sample_results <- function() {
  new_grade_results(data.frame(
    student  = c("Alice", "Alice", "Bob", "Bob", "Carol", "Carol"),
    exercise = c("ejercicio1", "ejercicio2", "ejercicio1", "ejercicio2",
                 "ejercicio1", "ejercicio2"),
    test     = c("test_ejercicio1_a", "test_ejercicio2_a",
                 "test_ejercicio1_a", "test_ejercicio2_a",
                 "test_ejercicio1_a", "test_ejercicio2_a"),
    status   = c("pass", "pass", "fail", "pass", "pass", "fail"),
    message  = NA_character_,
    duration = 0,
    stringsAsFactors = FALSE
  ))
}

test_that("plot_report (base backend) runs without error", {
  pdf(nullfile())
  on.exit(dev.off())
  result <- plot_report(sample_results(), ask = FALSE)
  expect_s3_class(result, "grade_results")
})

test_that("plot_report falls back to base when ggplot2 missing", {
  pdf(nullfile())
  on.exit(dev.off())
  if (requireNamespace("ggplot2", quietly = TRUE)) {
    result <- plot_report(sample_results(), backend = "ggplot2", ask = FALSE)
    expect_s3_class(result, "grade_results")
  } else {
    expect_warning(plot_report(sample_results(), backend = "ggplot2", ask = FALSE),
                   "ggplot2 not installed")
  }
})
