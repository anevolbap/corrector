make_submissions <- function(envir = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = envir)
  # Two students, both with ejercicio1, only one with ejercicio2.
  alice <- file.path(root, "alice_pereyra")
  bob   <- file.path(root, "bob_lopez")
  dir.create(alice, recursive = TRUE)
  dir.create(bob,   recursive = TRUE)
  writeLines("sumar <- function(a, b) a + b",      file.path(alice, "ejercicio1.R"))
  writeLines("restar <- function(a, b) a - b",     file.path(alice, "ejercicio2.R"))
  writeLines("sumar <- function(a, b) a - b",      file.path(bob,   "ejercicio1.R"))
  # Bob did not submit ejercicio2.
  root
}

make_test_dir <- function(envir = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = envir)
  writeLines(c(
    'test_ejercicio1_suma <- function() sumar(2, 3) == 5',
    'test_ejercicio1_neg  <- function() sumar(-1, 1) == 0'
  ), file.path(td, "test_ejercicio1.R"))
  writeLines(
    'test_ejercicio2_resta <- function() restar(5, 3) == 2',
    file.path(td, "test_ejercicio2.R")
  )
  td
}

test_that("grade_submissions on a directory produces one row per (student, exercise, test)", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  res <- suppressMessages(grade_submissions(subs, test_dir = tests))
  expect_s3_class(res, "grade_results")
  expect_setequal(unique(res$student), c("Alice", "Bob"))
  expect_setequal(unique(res$exercise), c("ejercicio1", "ejercicio2"))

  alice2 <- res[res$student == "Alice" & res$exercise == "ejercicio2", ]
  expect_true(all(alice2$status == "pass"))

  bob2 <- res[res$student == "Bob" & res$exercise == "ejercicio2", ]
  expect_equal(nrow(bob2), 1)
  expect_equal(as.character(bob2$status), "missing")
})

test_that("wide view marks missing submissions as NA", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  res  <- suppressMessages(grade_submissions(subs, test_dir = tests))
  wide <- as.data.frame(res, format = "wide")
  bob  <- wide[wide$student == "Bob", ]
  expect_true(is.na(bob$ejercicio2))
})

test_that("grade_submissions accepts a .zip archive", {
  subs <- make_submissions()
  zip_path <- withr::local_tempfile(fileext = ".zip")
  old <- setwd(subs)
  on.exit(setwd(old), add = TRUE)
  utils::zip(zip_path, files = list.files(), flags = "-rq")
  setwd(old)

  tests <- make_test_dir()
  res <- suppressMessages(grade_submissions(zip_path, test_dir = tests))
  expect_s3_class(res, "grade_results")
  expect_setequal(unique(res$student), c("Alice", "Bob"))
  expect_true(nrow(res) >= 3)
})

test_that("grade_submissions warns when test_dir has no test files", {
  subs  <- make_submissions()
  empty <- withr::local_tempdir()
  expect_warning(res <- grade_submissions(subs, test_dir = empty),
                 "No test files found")
  expect_equal(nrow(res), 0)
})

test_that("grade_submissions honours student_name_fn", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  res <- suppressMessages(grade_submissions(
    subs, test_dir = tests,
    student_name_fn = function(folder) toupper(folder)
  ))
  expect_setequal(unique(res$student), c("ALICE_PEREYRA", "BOB_LOPEZ"))
})
