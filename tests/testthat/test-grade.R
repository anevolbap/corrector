test_dir <- test_path("fixtures/tests")

test_that("grade_exercise passes correct implementation", {
  file <- test_path("fixtures/student_ok/ejercicio1.R")
  result <- grade_exercise(file, test_dir)
  expect_s3_class(result, "grade_results")
  expect_equal(nrow(result), 2)
  expect_true(all(result$status == "pass"))
})

test_that("grade_exercise fails wrong implementation", {
  file <- test_path("fixtures/student_fail/ejercicio1.R")
  result <- grade_exercise(file, test_dir)
  expect_true(any(result$status == "fail"))
})

test_that("grade_exercise returns source_error for unparseble file", {
  file <- test_path("fixtures/student_broken/ejercicio1.R")
  expect_warning(result <- grade_exercise(file, test_dir))
  expect_equal(nrow(result), 1)
  expect_equal(as.character(result$status), "source_error")
  expect_false(is.na(result$message))
})

test_that("grade_exercise warns and returns missing when no test file found", {
  file <- test_path("fixtures/student_ok/ejercicio99.R")
  expect_warning(result <- grade_exercise(file, test_dir), "No test file found")
  expect_equal(nrow(result), 1)
  expect_equal(as.character(result$status), "missing")
})

test_that("as.data.frame(format = 'wide') returns the legacy view", {
  file <- test_path("fixtures/student_ok/ejercicio1.R")
  result <- grade_exercise(file, test_dir, student = "Alice")
  wide <- as.data.frame(result, format = "wide")
  expect_equal(wide$student, "Alice")
  expect_true(wide$ejercicio1)
})

test_that("Latin-1 and UTF-8 student files both source", {
  dir   <- withr::local_tempdir()
  tests <- withr::local_tempdir()
  writeLines('test_ejercicio1_largo <- function() nchar(saludo()) == 3',
             file.path(tests, "test_ejercicio1.R"))
  # saludo <- function() "a<n-tilde>o", with the n-tilde in each encoding.
  head <- charToRaw('saludo <- function() "a')
  tail <- charToRaw('o"\n')
  for (bytes in list(as.raw(0xf1), as.raw(c(0xc3, 0xb1)))) {
    file <- file.path(dir, "ejercicio1.R")
    writeBin(c(head, bytes, tail), file)
    result <- grade_exercise(file, tests)
    expect_equal(as.character(result$status), "pass")
  }
})

for (engine in c("callr", "inproc")) {
  test_that(paste("student and test code can use stats and utils, engine", engine), {
    dir   <- withr::local_tempdir()
    tests <- withr::local_tempdir()
    writeLines("mediana <- function(x) median(utils::head(x, 3))",
               file.path(dir, "ejercicio1.R"))
    writeLines("test_ejercicio1_a <- function() mediana(c(1, 3, 2, 9)) == 2 && sd(c(1, 1)) == 0",
               file.path(tests, "test_ejercicio1.R"))
    res <- grade_exercise(file.path(dir, "ejercicio1.R"), tests, engine = engine)
    expect_equal(as.character(res$status), "pass")
  })
}

make_cheat <- function(envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = envir)
  writeLines(c(
    'sumar <- function(a, b) 1',
    '`==` <- function(e1, e2) TRUE',
    'test_ejercicio1_extra <- function() TRUE'
  ), file.path(dir, "ejercicio1.R"))
  file.path(dir, "ejercicio1.R")
}

test_that("student definitions do not mask base functions used by tests", {
  result <- grade_exercise(make_cheat(), test_dir)
  expect_true(all(result$status == "fail"))
  expect_match(result$message, "==", fixed = TRUE)
})

test_that("tests defined in the student file are not run", {
  result <- grade_exercise(make_cheat(), test_dir)
  expect_false("test_ejercicio1_extra" %in% result$test)
})

test_that("allow_masking lets students redefine named base functions", {
  dir   <- withr::local_tempdir()
  tests <- withr::local_tempdir()
  writeLines("factorial <- function(n) if (n <= 1) 1 else n * factorial(n - 1)",
             file.path(dir, "ejercicio1.R"))
  writeLines("test_ejercicio1_propia <- function() !identical(factorial, base::factorial)",
             file.path(tests, "test_ejercicio1.R"))
  file <- file.path(dir, "ejercicio1.R")
  expect_equal(as.character(grade_exercise(file, tests)$status), "fail")
  allowed <- grade_exercise(file, tests, allow_masking = "factorial")
  expect_equal(as.character(allowed$status), "pass")
  expect_true(is.na(allowed$message))
})
