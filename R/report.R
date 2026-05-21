#' Summarise grading results
#'
#' Computes pass rate per exercise and score per student, plus counts of
#' errors, timeouts, and missing submissions. The returned object has a
#' [print()] method that renders a readable console summary.
#'
#' @param results A [grade_results] object returned by [grade_submissions()]
#'   or [grade_exercise()].
#' @return A `grade_report` object (a list) with components:
#'   \describe{
#'     \item{`pass_rate_by_exercise`}{Named numeric vector (0-1). Fraction of
#'       students whose every test passed.}
#'     \item{`score_by_student`}{Named numeric vector (0-1). Mean pass rate
#'       across the student's exercises.}
#'     \item{`overall_mean`}{Scalar numeric (0-1).}
#'     \item{`issue_counts`}{Named integer vector with counts of `error`,
#'       `timeout`, and `missing` rows.}
#'   }
#' @export
grade_report <- function(results) {
  results <- ensure_grade_results(results)
  wide <- as.data.frame(results, format = "wide")
  exercise_cols <- setdiff(names(wide), "student")

  pass_rate <- vapply(exercise_cols, function(ex) {
    mean(wide[[ex]], na.rm = TRUE)
  }, numeric(1))
  names(pass_rate) <- exercise_cols

  student_scores <- vapply(seq_len(nrow(wide)), function(i) {
    mean(unlist(wide[i, exercise_cols, drop = FALSE]), na.rm = TRUE)
  }, numeric(1))
  names(student_scores) <- wide$student

  issue_counts <- c(
    error   = sum(results$status == "error"),
    timeout = sum(results$status == "timeout"),
    missing = sum(results$status == "missing"),
    source_error = sum(results$status == "source_error")
  )

  structure(
    list(
      pass_rate_by_exercise = pass_rate,
      score_by_student      = student_scores,
      overall_mean          = mean(student_scores, na.rm = TRUE),
      issue_counts          = issue_counts
    ),
    class = "grade_report"
  )
}

#' @export
print.grade_report <- function(x, ...) {
  pct <- function(v) sprintf("%.0f%%", v * 100)

  cat("=== Grade Report ===\n\n")

  cat("Pass rate by exercise:\n")
  for (ex in names(x$pass_rate_by_exercise)) {
    cat(sprintf("  %-25s %s\n", ex, pct(x$pass_rate_by_exercise[[ex]])))
  }

  cat(sprintf("\nOverall mean score: %s\n", pct(x$overall_mean)))

  if (any(x$issue_counts > 0)) {
    cat("\nIssues:\n")
    for (nm in names(x$issue_counts)) {
      n <- x$issue_counts[[nm]]
      if (n > 0) cat(sprintf("  %-13s %d\n", nm, n))
    }
  }

  cat("\nScore by student (descending):\n")
  sorted <- sort(x$score_by_student, decreasing = TRUE)
  bar_width <- 20L
  for (nm in names(sorted)) {
    bar <- strrep("#", round(sorted[[nm]] * bar_width))
    cat(sprintf("  %-20s %-*s %s\n", nm, bar_width, bar, pct(sorted[[nm]])))
  }

  invisible(x)
}

ensure_grade_results <- function(x) {
  if (inherits(x, "grade_results")) return(x)
  stop("Expected a 'grade_results' object; got: ", class(x)[[1]])
}
