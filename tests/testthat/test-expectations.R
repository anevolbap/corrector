make_expect_tests <- function(envir = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = envir)
  writeLines(c(
    'library(testthat)',
    'test_ejercicio1_suma <- function() expect_equal(sumar(2, 3), 5)',
    'test_ejercicio1_dos <- function() {',
    '  expect_equal(sumar(1, 1), 2)',
    '  expect_true(is.numeric(sumar(1, 1)))',
    '}'
  ), file.path(td, "test_ejercicio1.R"))
  td
}

for (engine in c("callr", "inproc")) {
  test_that(paste("a skip() in a test is recorded, engine", engine), {
    tests <- withr::local_tempdir()
    writeLines(c(
      'test_ejercicio1_a <- function() testthat::skip("no data")',
      'test_ejercicio1_b <- function() sumar(1, 1) == 2'
    ), file.path(tests, "test_ejercicio1.R"))
    res <- grade_exercise(test_path("fixtures/student_ok/ejercicio1.R"), tests,
                          engine = engine)
    expect_equal(as.character(res$status[res$test == "test_ejercicio1_a"]), "error")
    expect_match(res$message[res$test == "test_ejercicio1_a"], "skipped: no data")
    expect_equal(as.character(res$status[res$test == "test_ejercicio1_b"]), "pass")
  })

  test_that(paste("testthat expectations pass and fail, engine", engine), {
    tests <- make_expect_tests()
    ok   <- grade_exercise(test_path("fixtures/student_ok/ejercicio1.R"), tests,
                           engine = engine)
    bad  <- grade_exercise(test_path("fixtures/student_fail/ejercicio1.R"), tests,
                           engine = engine)
    expect_true(all(ok$status == "pass"))
    expect_true(all(bad$status == "fail"))
    expect_match(bad$message, "not equal", all = FALSE)
  })

  test_that(paste("students cannot redefine testthat expectations, engine", engine), {
    tests <- make_expect_tests()
    dir <- withr::local_tempdir()
    writeLines(c('sumar <- function(a, b) 0',
                 'expect_equal <- function(...) invisible(TRUE)',
                 'expect_true <- function(...) invisible(TRUE)'),
               file.path(dir, "ejercicio1.R"))
    res <- grade_exercise(file.path(dir, "ejercicio1.R"), tests, engine = engine)
    expect_true(all(res$status == "fail"))
  })
}
