iso_tests <- function(envir = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = envir)
  writeLines(c(
    "test_ejercicio1_suma <- function() sumar(2, 3) == 5",
    "test_ejercicio1_igual <- function() isTRUE(all.equal(sumar(1, 1), 2))",
    "test_ejercicio1_identico <- function() identical(sumar(1, 1), 2)"
  ), file.path(td, "test_ejercicio1.R"))
  td
}

iso_file <- function(lines, envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = envir)
  writeLines(lines, file.path(dir, "ejercicio1.R"))
  file.path(dir, "ejercicio1.R")
}

grade_iso <- function(lines, tests = iso_tests(parent.frame()), ...) {
  grade_exercise(iso_file(lines, parent.frame()), tests, engine = "isolated", ...)
}

test_that("isolated engine grades correct and wrong code", {
  ok  <- grade_iso("sumar <- function(a, b) a + b")
  bad <- grade_iso("sumar <- function(a, b) a - b")
  expect_true(all(ok$status == "pass"))
  expect_true(all(bad$status == "fail"))
})

test_that("isolated engine blocks attach() cheats", {
  res <- grade_iso(c(
    'attach(list(`==` = function(e1, e2) TRUE, isTRUE = function(x) TRUE,',
    '            identical = function(x, y, ...) TRUE), name = "trampa")',
    "sumar <- function(a, b) 0"
  ))
  expect_true(all(res$status == "fail"))
  expect_match(res$message, "tampering: attached trampa", fixed = TRUE, all = TRUE)
})

test_that("isolated engine blocks S3 method cheats, even registered ones", {
  res <- grade_iso(c(
    "Ops.trampa <- function(e1, e2) TRUE",
    "all.equal.trampa <- function(target, current, ...) TRUE",
    'registerS3method("Ops", "trampa", Ops.trampa)',
    'registerS3method("all.equal", "trampa", all.equal.trampa)',
    'sumar <- function(a, b) structure(0, class = "trampa")'
  ))
  expect_true(all(res$status == "fail"))
})

test_that("isolated engine blocks global env and base binding cheats", {
  res <- grade_iso(c(
    'assign("isTRUE", function(x) TRUE, envir = globalenv())',
    'unlockBinding("identical", baseenv())',
    'assign("identical", function(x, y, ...) TRUE, envir = baseenv())',
    "sumar <- function(a, b) 0"
  ))
  expect_true(all(res$status == "fail"))
})

test_that("isolated engine refuses results that carry code", {
  tests <- withr::local_tempdir()
  writeLines("test_ejercicio1_a <- function() is.function(fabrica())",
             file.path(tests, "test_ejercicio1.R"))
  res <- grade_iso("fabrica <- function() function() TRUE", tests = tests)
  expect_equal(as.character(res$status), "error")
  expect_match(res$message, "returned a function")
})

test_that("isolated engine keeps student state between calls", {
  tests <- withr::local_tempdir()
  writeLines("test_ejercicio1_a <- function() { contar(); contar(); contar() == 3 }",
             file.path(tests, "test_ejercicio1.R"))
  res <- grade_iso(c("n <- 0", "contar <- function() { n <<- n + 1; n }"), tests = tests)
  expect_equal(as.character(res$status), "pass")
})

test_that("isolated engine handles errors, timeouts and data frames", {
  tests <- withr::local_tempdir()
  writeLines(c(
    "test_ejercicio1_err <- function() falla() == 1",
    "test_ejercicio1_lento <- function() lento() == 1",
    "test_ejercicio1_df <- function() identical(tabla()$x, 1:3)",
    "test_ejercicio1_luego <- function() sumar(1, 1) == 2"
  ), file.path(tests, "test_ejercicio1.R"))
  res <- grade_iso(c(
    'falla <- function() stop("roto")',
    "lento <- function() { repeat {} }",
    "tabla <- function() data.frame(x = 1:3)",
    "sumar <- function(a, b) a + b"
  ), tests = tests, timeout = 2)
  st <- setNames(as.character(res$status), sub("test_ejercicio1_", "", res$test))
  expect_equal(st[["err"]], "error")
  expect_match(res$message[res$test == "test_ejercicio1_err"], "roto")
  expect_equal(st[["lento"]], "timeout")
  expect_equal(st[["df"]], "pass")
  # The session is restarted after the timeout, so later tests still run.
  expect_equal(st[["luego"]], "pass")
})

test_that("isolated engine reports source errors and testthat expectations", {
  expect_warning(res <- grade_iso("this is not R"), "Failed to source")
  expect_equal(as.character(res$status), "source_error")
  tests <- withr::local_tempdir()
  writeLines(c("library(testthat)",
               "test_ejercicio1_a <- function() expect_equal(sumar(1, 1), 2)"),
             file.path(tests, "test_ejercicio1.R"))
  expect_equal(as.character(grade_iso("sumar <- function(a, b) a + b", tests = tests)$status), "pass")
  expect_equal(as.character(grade_iso("sumar <- function(a, b) 0", tests = tests)$status), "fail")
})

test_that("grade_submissions runs the isolated engine with workers", {
  subs <- withr::local_tempdir()
  for (s in c("ana", "beto")) dir.create(file.path(subs, s))
  writeLines("sumar <- function(a, b) a + b", file.path(subs, "ana", "ejercicio1.R"))
  writeLines("sumar <- function(a, b) 0", file.path(subs, "beto", "ejercicio1.R"))
  res <- suppressMessages(grade_submissions(subs, iso_tests(), engine = "isolated",
                                            workers = 2))
  expect_true(all(res$status[res$student == "Ana"] == "pass"))
  expect_true(all(res$status[res$student == "Beto"] == "fail"))
})
