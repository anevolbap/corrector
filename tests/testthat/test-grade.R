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

test_that("grade_exercise records timeout status", {
  # setTimeLimit is unreliable for Sys.sleep on some platforms; the callr
  # engine added in 0.2.0 is the robust path. Replaced in test-callr.R.
  skip_on_cran()
  skip("setTimeLimit + Sys.sleep is unreliable; covered by callr engine tests")
  file <- test_path("fixtures/student_timeout/ejercicio1.R")
  result <- grade_exercise(file, test_dir, timeout = 1)
  row <- result[result$test == "test_ejercicio1_suma", ]
  expect_equal(as.character(row$status), "timeout")
})

test_that("as.data.frame(format = 'wide') returns the legacy view", {
  file <- test_path("fixtures/student_ok/ejercicio1.R")
  result <- grade_exercise(file, test_dir, student = "Alice")
  wide <- as.data.frame(result, format = "wide")
  expect_equal(wide$student, "Alice")
  expect_true(wide$ejercicio1)
})
