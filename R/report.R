#' Summarise grading results
#'
#' Computes pass rate per exercise and score per student, plus counts of
#' errors, timeouts, and missing submissions. The returned object has a
#' [print()] method that renders a readable console summary.
#'
#' @param results A [grade_results] object returned by [grade_submissions()]
#'   or [grade_exercise()].
#' @param scoring `"all"` (default): an exercise counts as passed only if
#'   every test passes. `"partial"`: it scores the fraction of tests that
#'   pass. See [student_scores()].
#' @param weights Optional named numeric vector of test or exercise weights.
#'   See [student_scores()].
#' @return A `grade_report` object (a list) with components:
#'   \describe{
#'     \item{`pass_rate_by_exercise`}{Named numeric vector (0-1). Mean
#'       exercise score across students.}
#'     \item{`score_by_student`}{Named numeric vector (0-1). The student's
#'       `total` from [student_scores()].}
#'
#'   In both, a `missing` exercise or one with a `source_error` counts as 0.
#'     \item{`overall_mean`}{Scalar numeric (0-1).}
#'     \item{`issue_counts`}{Named integer vector with counts of `error`,
#'       `timeout`, `missing`, and `source_error` rows.}
#'   }
#' @export
#' @examples
#' report <- grade_report(example_results())
#' report
#' report$score_by_student
grade_report <- function(results, scoring = c("all", "partial"), weights = NULL) {
  results <- ensure_grade_results(results)
  scoring <- match.arg(scoring)
  summ <- summary_scores(results, scoring, weights)
  pass_rate <- summ$pass_rate
  student_scores <- summ$by_student

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
  if (length(x$score_by_student) == 0) {
    cat("No results.\n")
    return(invisible(x))
  }

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

# Pass rate per exercise and score per student, shared by grade_report(),
# export_to_html() and plot_report(). Missing exercises count as 0.
summary_scores <- function(results, scoring = "all", weights = NULL) {
  scores <- student_scores(results, scoring = scoring, weights = weights)
  exercise_cols <- setdiff(names(scores), c("student", "total"))

  pass_rate <- vapply(exercise_cols, function(ex) {
    v <- scores[[ex]]
    mean(ifelse(is.na(v), 0, v))
  }, numeric(1))
  names(pass_rate) <- exercise_cols

  by_student <- stats::setNames(scores$total, scores$student)
  list(pass_rate = pass_rate, by_student = by_student)
}

ensure_grade_results <- function(x) {
  if (inherits(x, "grade_results")) return(x)
  stop("Expected a 'grade_results' object; got: ", class(x)[[1]])
}
