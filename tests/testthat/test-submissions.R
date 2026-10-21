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

test_that("grade_submissions ignores stray files and steps into a lone top folder", {
  subs <- make_submissions()
  outer <- withr::local_tempdir()
  file.copy(subs, outer, recursive = TRUE)
  top <- file.path(outer, basename(subs))
  writeLines("notas", file.path(top, "LEEME.txt"))
  dir.create(file.path(outer, "__MACOSX"))
  dir.create(file.path(top, ".hidden"))

  tests <- make_test_dir()
  res <- suppressMessages(grade_submissions(outer, test_dir = tests))
  expect_setequal(unique(res$student), c("Alice", "Bob"))
})

strip_duration <- function(res) {
  df <- as.data.frame(res)
  df$duration <- NULL
  df
}

test_that("workers > 1 gives the same results in the same order", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  one   <- suppressMessages(grade_submissions(subs, test_dir = tests))
  three <- suppressMessages(grade_submissions(subs, test_dir = tests, workers = 3))
  expect_equal(strip_duration(three), strip_duration(one))
})

test_that("inproc and callr engines agree on grade_submissions", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  callr  <- suppressMessages(grade_submissions(subs, test_dir = tests))
  inproc <- suppressMessages(grade_submissions(subs, test_dir = tests,
                                               engine = "inproc"))
  expect_equal(strip_duration(inproc), strip_duration(callr))
})

test_that("workers > 1 runs students at the same time", {
  skip_on_cran()
  subs  <- withr::local_tempdir()
  tests <- make_test_dir()
  for (s in c("ana", "beto", "carla", "dario")) {
    dir.create(file.path(subs, s))
    writeLines("sumar <- function(a, b) { Sys.sleep(2); a + b }",
               file.path(subs, s, "ejercicio1.R"))
  }
  t0 <- Sys.time()
  res <- suppressMessages(grade_submissions(subs, test_dir = tests, workers = 4))
  elapsed <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  # Sequential: 4 students x 2 tests x 2 s = 16 s at least.
  expect_lt(elapsed, 10)
  expect_true(all(res$status[res$exercise == "ejercicio1"] == "pass"))
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

test_that("students with the same display name are kept apart", {
  subs  <- make_submissions()
  tests <- make_test_dir()
  dir.create(file.path(subs, "alice_gomez"))
  writeLines("sumar <- function(a, b) 0", file.path(subs, "alice_gomez", "ejercicio1.R"))
  expect_warning(
    res <- suppressMessages(grade_submissions(subs, test_dir = tests)),
    "same display name"
  )
  expect_setequal(unique(res$student), c("alice_gomez", "alice_pereyra", "Bob"))
  wide <- as.data.frame(res, format = "wide")
  expect_equal(nrow(wide), 3)
})
