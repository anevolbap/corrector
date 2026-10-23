test_that("container engine explains a missing tool", {
  withr::local_options(corrector.container_cmd = "no-such-container-tool")
  expect_error(grade_exercise(test_path("fixtures/student_ok/ejercicio1.R"),
                              test_path("fixtures/tests"), engine = "container"),
               "needs no-such-container-tool")
})

test_that("container engine explains a missing image", {
  skip_if(Sys.which("docker") == "", "no docker")
  withr::local_options(corrector.container_image = "corrector-image-that-does-not-exist")
  expect_error(grade_exercise(test_path("fixtures/student_ok/ejercicio1.R"),
                              test_path("fixtures/tests"), engine = "container"),
               "not found. Build it with")
})

has_runner_image <- function() {
  nzchar(Sys.which("docker")) &&
    identical(suppressWarnings(system2("docker", c("image", "inspect", "corrector-runner"),
                                       stdout = FALSE, stderr = FALSE)), 0L)
}

test_that("container engine grades and keeps student code inside", {
  skip_on_cran()
  skip_if_not(has_runner_image(), "no corrector-runner image")
  tests <- withr::local_tempdir()
  writeLines(c(
    "test_ejercicio1_suma <- function() sumar(2, 3) == 5",
    "test_ejercicio1_secreto <- function() identical(leer(), 'nada')",
    "test_ejercicio1_red <- function() identical(bajar(), 'sin red')"
  ), file.path(tests, "test_ejercicio1.R"))
  # A file on the host that student code must not see.
  secret <- withr::local_tempfile(fileext = ".txt")
  writeLines("secreto", secret)
  dir <- withr::local_tempdir()
  writeLines(c(
    "sumar <- function(a, b) a + b",
    sprintf("leer <- function() if (file.exists('%s')) 'visto' else 'nada'", secret),
    "bajar <- function() tryCatch({ readLines(url('https://example.com')); 'con red' },",
    "                           error = function(e) 'sin red', warning = function(w) 'sin red')"
  ), file.path(dir, "ejercicio1.R"))
  res <- grade_exercise(file.path(dir, "ejercicio1.R"), tests, engine = "container",
                        timeout = 20)
  st <- setNames(as.character(res$status), sub("test_ejercicio1_", "", res$test))
  expect_equal(st[["suma"]], "pass")
  expect_equal(st[["secreto"]], "pass")
  expect_equal(st[["red"]], "pass")
})

test_that("container engine blocks the attach() cheat", {
  skip_on_cran()
  skip_if_not(has_runner_image(), "no corrector-runner image")
  dir <- withr::local_tempdir()
  # sumar() always returns 1, so both fixture tests should fail.
  writeLines(c('attach(list(`==` = function(e1, e2) TRUE), name = "trampa")',
               "sumar <- function(a, b) 1"),
             file.path(dir, "ejercicio1.R"))
  res <- grade_exercise(file.path(dir, "ejercicio1.R"), test_path("fixtures/tests"),
                        engine = "container", timeout = 20)
  expect_true(all(res$status == "fail"))
})
