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
