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
  result <- grade_exercise(file, test_dir, engine = "callr")
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
