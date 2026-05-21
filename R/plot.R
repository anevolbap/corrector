#' Plot a visual summary of grading results
#'
#' Produces three base-R plots in sequence:
#' \enumerate{
#'   \item Student scores ranked (horizontal bar chart).
#'   \item Pass rate per exercise (bar chart).
#'   \item Pass/fail heatmap (students x exercises).
#' }
#'
#' @param results Data frame returned by [grade_submissions()].
#' @param ask If `TRUE` (default in interactive sessions), pause between plots.
#'   Pass `FALSE` when rendering to a file device (PDF, PNG, etc.).
#' @return `results`, invisibly.
#' @importFrom graphics abline axis barplot box image legend par
#' @importFrom stats setNames
#' @export
plot_report <- function(results, ask = interactive()) {
  exercise_cols <- setdiff(names(results), "student")

  pass_rate <- colMeans(results[exercise_cols], na.rm = TRUE)
  student_scores <- setNames(
    rowMeans(results[exercise_cols], na.rm = TRUE),
    results$student
  )

  old_par <- par(ask = ask)
  on.exit(par(old_par))

  # 1. Student scores ranked
  sorted <- sort(student_scores)
  barplot(
    sorted,
    horiz  = TRUE,
    las    = 1,
    xlim   = c(0, 1),
    xlab   = "Score",
    main   = "Score by student",
    col    = ifelse(sorted >= 0.5, "#d4edda", "#f8d7da"),
    border = "gray70"
  )
  abline(v = mean(sorted), lty = 2, col = "gray40")
  legend("bottomright", legend = c("Pass", "Fail", "Mean"),
         fill = c("#d4edda", "#f8d7da", NA), border = c("gray70", "gray70", NA),
         lty = c(NA, NA, 2), col = c(NA, NA, "gray40"), bty = "n")

  # 2. Pass rate per exercise
  barplot(
    pass_rate,
    las    = 2,
    ylim   = c(0, 1),
    ylab   = "Pass rate",
    main   = "Pass rate by exercise",
    col    = ifelse(pass_rate >= 0.5, "#d4edda", "#f8d7da"),
    border = "gray70"
  )
  abline(h = mean(pass_rate), lty = 2, col = "gray40")

  # 3. Pass/fail heatmap
  mat   <- as.matrix(results[exercise_cols]) * 1L
  n_ex  <- ncol(mat)
  n_stu <- nrow(mat)

  image(
    x    = seq_len(n_ex),
    y    = seq_len(n_stu),
    z    = t(mat),
    col  = c("#f8d7da", "#d4edda"),
    xlab = "",
    ylab = "",
    main = "Results heatmap",
    axes = FALSE
  )
  axis(1, at = seq_len(n_ex),  labels = exercise_cols,   las = 2)
  axis(2, at = seq_len(n_stu), labels = results$student, las = 1)
  box()

  invisible(results)
}
