test_dir <- test_path("fixtures/tests")

test_that("callr engine grades a correct submission", {
  skip_if_not_installed("callr")
  file <- test_path("fixtures/student_ok/ejercicio1.R")
  result <- grade_exercise(file, test_dir, engine = "callr")
  expect_true(all(result$status == "pass"))
  expect_equal(nrow(result), 2)
})

test_that("callr engine flags failing tests", {
  skip_if_not_installed("callr")
  file <- test_path("fixtures/student_fail/ejercicio1.R")
  result <- grade_exercise(file, test_dir, engine = "callr")
  expect_true(any(result$status == "fail"))
})

test_that("callr engine surfaces source_error", {
  skip_if_not_installed("callr")
  file <- test_path("fixtures/student_broken/ejercicio1.R")
  expect_warning(result <- grade_exercise(file, test_dir, engine = "callr"),
                 "Failed to source")
  expect_equal(as.character(result$status[1]), "source_error")
})

test_that("callr engine actually kills a Sys.sleep timeout", {
  skip_if_not_installed("callr")
  skip_on_cran()
  file <- test_path("fixtures/student_timeout/ejercicio1.R")
  t0 <- Sys.time()
  result <- grade_exercise(file, test_dir, timeout = 1, engine = "callr")
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  expect_lt(elapsed, 15)
  expect_true(any(as.character(result$status) == "timeout"))
})

test_that("default engine keeps student side effects out of the session", {
  dir <- withr::local_tempdir()
  wd  <- withr::local_tempdir()
  writeLines(c(
    'sumar <- function(a, b) a + b',
    'corrector_leak <<- TRUE',
    'writeLines("x", "salida.txt")'
  ), file.path(dir, "ejercicio1.R"))
  file <- normalizePath(file.path(dir, "ejercicio1.R"))
  tests <- normalizePath(test_dir)
  withr::with_dir(wd, result <- grade_exercise(file, tests))
  expect_true(all(result$status == "pass"))
  expect_false(exists("corrector_leak", envir = globalenv()))
  expect_false(file.exists(file.path(wd, "salida.txt")))
})

test_that("grading defaults to callr with a finite timeout", {
  for (f in list(grade_exercise, grade_submissions)) {
    expect_equal(eval(formals(f)$engine)[[1]], "callr")
    expect_equal(formals(f)$timeout, 10)
  }
})

test_that("callr engine does not let students mask base functions", {
  skip_if_not_installed("callr")
  dir <- withr::local_tempdir()
  writeLines(c('sumar <- function(a, b) 1', '`==` <- function(e1, e2) TRUE'),
             file.path(dir, "ejercicio1.R"))
  result <- grade_exercise(file.path(dir, "ejercicio1.R"), test_dir,
                           engine = "callr")
  expect_true(all(result$status == "fail"))
  expect_match(result$message, "==", fixed = TRUE)
})
