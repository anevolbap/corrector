sample_results <- function() {
  new_grade_results(data.frame(
    student  = c("Alice", "Alice", "Bob", "Bob", "Carol", "Carol"),
    exercise = c("ejercicio1", "ejercicio2", "ejercicio1", "ejercicio2",
                 "ejercicio1", "ejercicio2"),
    test     = paste0("test_", c("ejercicio1_a", "ejercicio2_a"), recycle0 = FALSE)[
      c(1, 2, 1, 2, 1, 2)],
    status   = c("pass", "pass", "fail", "pass", "pass", "fail"),
    message  = NA_character_,
    duration = 0,
    stringsAsFactors = FALSE
  ))
}

test_that("grade_report computes correct pass rates", {
  r <- grade_report(sample_results())
  expect_equal(r$pass_rate_by_exercise[["ejercicio1"]], 2 / 3)
  expect_equal(r$pass_rate_by_exercise[["ejercicio2"]], 2 / 3)
})

test_that("grade_report computes correct student scores", {
  r <- grade_report(sample_results())
  expect_equal(r$score_by_student[["Alice"]], 1.0)
  expect_equal(r$score_by_student[["Bob"]],   0.5)
  expect_equal(r$score_by_student[["Carol"]], 0.5)
})

test_that("grade_report overall_mean is correct", {
  r <- grade_report(sample_results())
  expect_equal(r$overall_mean, mean(c(1.0, 0.5, 0.5)))
})

test_that("grade_report issue_counts surface error/timeout/missing", {
  res <- new_grade_results(data.frame(
    student  = c("Alice", "Bob", "Carol"),
    exercise = "ejercicio1",
    test     = c("test_ejercicio1_a", NA, NA),
    status   = c("error", "timeout", "missing"),
    message  = c("boom", "elapsed time limit", "no submission"),
    duration = c(0.1, 1, NA),
    stringsAsFactors = FALSE
  ))
  r <- grade_report(res)
  expect_equal(r$issue_counts[["error"]], 1)
  expect_equal(r$issue_counts[["timeout"]], 1)
  expect_equal(r$issue_counts[["missing"]], 1)
})

test_that("print.grade_report produces output without error", {
  r <- grade_report(sample_results())
  expect_output(print(r), "Grade Report")
  expect_output(print(r), "Pass rate")
  expect_output(print(r), "Alice")
})
