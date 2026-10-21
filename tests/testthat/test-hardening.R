test_that("zip entries that escape the extraction folder are refused", {
  root <- withr::local_tempdir()
  inner <- file.path(root, "src", "inner")
  dir.create(inner, recursive = TRUE)
  writeLines("x", file.path(root, "src", "evil.txt"))
  writeLines("sumar <- function(a, b) a + b", file.path(inner, "ejercicio1.R"))
  zip_path <- file.path(root, "evil.zip")
  withr::with_dir(inner, utils::zip(zip_path, c("ejercicio1.R", "../evil.txt"),
                                    flags = "-q"))
  expect_error(extract_if_zip(zip_path), "outside")
})

make_student <- function(envir = parent.frame()) {
  subs <- withr::local_tempdir(.local_envir = envir)
  for (s in c("ana", "beto")) {
    dir.create(file.path(subs, s))
    writeLines("sumar <- function(a, b) a + b", file.path(subs, s, "ejercicio1.R"))
  }
  subs
}

for (engine in c("callr", "inproc")) {
  test_that(paste("a broken test file stops grading, engine", engine), {
    tests <- withr::local_tempdir()
    writeLines(c("test_ejercicio1_a <- function() sumar(1, 1) == 2", "this is ( broken"),
               file.path(tests, "test_ejercicio1.R"))
    subs <- make_student()
    expect_error(
      grade_exercise(file.path(subs, "ana", "ejercicio1.R"), tests, engine = engine),
      "test_ejercicio1.R could not be loaded"
    )
    expect_error(
      suppressMessages(grade_submissions(subs, tests, engine = engine)),
      "test_ejercicio1.R could not be loaded"
    )
  })

  test_that(paste("a test file without test functions warns once, engine", engine), {
    tests <- withr::local_tempdir()
    writeLines("ayuda <- function() 1", file.path(tests, "test_ejercicio1.R"))
    subs <- make_student()
    warnings <- character()
    withCallingHandlers(
      suppressMessages(grade_submissions(subs, tests, engine = engine)),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    expect_length(warnings, 1)
    expect_match(warnings, "test_ejercicio1_")
  })
}

one_file <- function(lines, envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = envir)
  writeLines(lines, file.path(dir, "ejercicio1.R"))
  file.path(dir, "ejercicio1.R")
}

for (engine in c("callr", "inproc")) {
  test_that(paste("a student file that never finishes loading times out, engine", engine), {
    file <- one_file(c("sumar <- function(a, b) a + b", "repeat {}"))
    t0 <- Sys.time()
    res <- grade_exercise(file, test_path("fixtures/tests"), timeout = 1, engine = engine)
    expect_lt(as.numeric(difftime(Sys.time(), t0, units = "secs")), 15)
    expect_true(all(res$status == "timeout"))
    expect_equal(nrow(res), 2)
    expect_match(res$message, "load", all = TRUE)
  })

  test_that(paste("quit() in student code is an error, engine", engine), {
    expect_warning(
      top <- grade_exercise(one_file(c("sumar <- function(a, b) a + b", "quit()")),
                            test_path("fixtures/tests"), engine = engine),
      "quit"
    )
    expect_equal(as.character(top$status), "source_error")
    inside <- grade_exercise(one_file("sumar <- function(a, b) q()"),
                             test_path("fixtures/tests"), engine = engine)
    expect_true(all(inside$status == "error"))
    expect_match(inside$message, "not allowed", all = TRUE)
  })
}

test_that("inproc restores the working directory and options", {
  file <- one_file(c("setwd(tempdir())", "options(digits = 1)",
                     "sumar <- function(a, b) a + b"))
  wd <- getwd()
  digits <- getOption("digits")
  grade_exercise(file, test_path("fixtures/tests"), engine = "inproc")
  expect_equal(getwd(), wd)
  expect_equal(getOption("digits"), digits)
})

test_that("bad paths and arguments give clear errors", {
  subs  <- make_student()
  tests <- test_path("fixtures/tests")
  nope  <- file.path(withr::local_tempdir(), "nope")
  expect_error(grade_submissions(nope, tests), "does not exist")
  expect_error(grade_submissions(subs, nope), "does not exist")
  expect_error(grade_exercise(file.path(nope, "ejercicio1.R"), tests), "does not exist")
  expect_error(grade_exercise(file.path(subs, "ana", "ejercicio1.R"), nope), "does not exist")
  expect_error(grade_submissions(subs, tests, timeout = -1), "timeout")
  expect_error(grade_submissions(subs, tests, timeout = "10"), "timeout")
  expect_error(grade_submissions(subs, tests, workers = 0), "workers")
  expect_error(grade_submissions(subs, tests, workers = 1.5), "workers")
})

test_that("a folder with no student folders warns and returns no rows", {
  empty <- withr::local_tempdir()
  expect_warning(res <- grade_submissions(empty, test_path("fixtures/tests")),
                 "No student folders")
  expect_s3_class(res, "grade_results")
  expect_equal(nrow(res), 0)
})

test_that("export_to_csv does not write live spreadsheet formulas", {
  res <- new_grade_results(data.frame(
    student = c("=cmd", "Ana"), exercise = "e1", test = "test_e1_a",
    status = "error",
    message = c('=HYPERLINK("http://x","click")', "plain message"),
    duration = 0, stringsAsFactors = FALSE
  ))
  path <- withr::local_tempfile(fileext = ".csv")
  export_to_csv(res, path, format = "long")
  out <- read.csv(path)
  expect_equal(out$message, c("'=HYPERLINK(\"http://x\",\"click\")", "plain message"))
  expect_equal(out$student, c("'=cmd", "Ana"))
})
