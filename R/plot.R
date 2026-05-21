#' Plot a visual summary of grading results
#'
#' Produces three plots in sequence:
#' \enumerate{
#'   \item Student scores ranked (horizontal bar chart).
#'   \item Pass rate per exercise (bar chart).
#'   \item Pass/fail heatmap (students x exercises).
#' }
#'
#' @param results A [grade_results] object.
#' @param ask If `TRUE` (default in interactive sessions), pause between plots.
#'   Pass `FALSE` when rendering to a file device (PDF, PNG, etc.).
#' @param backend `"base"` (default) uses base graphics, no extra dependencies.
#'   `"ggplot2"` uses ggplot2 when installed and falls back to base R with a
#'   warning otherwise.
#' @return `results`, invisibly.
#' @importFrom graphics abline axis barplot box image legend par
#' @importFrom stats setNames
#' @export
plot_report <- function(results, ask = interactive(), backend = c("base", "ggplot2")) {
  results <- ensure_grade_results(results)
  backend <- match.arg(backend)

  if (backend == "ggplot2" && !requireNamespace("ggplot2", quietly = TRUE)) {
    warning("ggplot2 not installed; falling back to base graphics.")
    backend <- "base"
  }

  if (backend == "ggplot2") {
    plot_report_ggplot(results)
    return(invisible(results))
  }

  plot_report_base(results, ask = ask)
  invisible(results)
}

plot_report_base <- function(results, ask) {
  wide <- as.data.frame(results, format = "wide")
  exercise_cols <- setdiff(names(wide), "student")

  pass_rate <- vapply(exercise_cols, function(ex) mean(wide[[ex]], na.rm = TRUE), numeric(1))
  student_scores <- setNames(
    vapply(seq_len(nrow(wide)), function(i) {
      mean(unlist(wide[i, exercise_cols, drop = FALSE]), na.rm = TRUE)
    }, numeric(1)),
    wide$student
  )

  old_par <- par(ask = ask)
  on.exit(par(old_par))

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
  abline(v = mean(sorted, na.rm = TRUE), lty = 2, col = "gray40")
  legend("bottomright", legend = c("Pass", "Fail", "Mean"),
         fill = c("#d4edda", "#f8d7da", NA), border = c("gray70", "gray70", NA),
         lty = c(NA, NA, 2), col = c(NA, NA, "gray40"), bty = "n")

  barplot(
    pass_rate,
    las    = 2,
    ylim   = c(0, 1),
    ylab   = "Pass rate",
    main   = "Pass rate by exercise",
    col    = ifelse(pass_rate >= 0.5, "#d4edda", "#f8d7da"),
    border = "gray70"
  )
  abline(h = mean(pass_rate, na.rm = TRUE), lty = 2, col = "gray40")

  mat <- vapply(exercise_cols, function(ex) {
    v <- wide[[ex]]
    ifelse(is.na(v), NA_integer_, as.integer(v))
  }, integer(nrow(wide)))
  if (is.null(dim(mat))) mat <- matrix(mat, nrow = nrow(wide))
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
  axis(1, at = seq_len(n_ex),  labels = exercise_cols, las = 2)
  axis(2, at = seq_len(n_stu), labels = wide$student, las = 1)
  box()
}

plot_report_ggplot <- function(results) {
  wide <- as.data.frame(results, format = "wide")
  exercise_cols <- setdiff(names(wide), "student")

  pass_rate <- data.frame(
    exercise  = exercise_cols,
    pass_rate = vapply(exercise_cols, function(ex) mean(wide[[ex]], na.rm = TRUE), numeric(1)),
    stringsAsFactors = FALSE
  )
  pass_rate$exercise <- factor(pass_rate$exercise, levels = pass_rate$exercise)

  scores <- data.frame(
    student = wide$student,
    score   = vapply(seq_len(nrow(wide)), function(i) {
      mean(unlist(wide[i, exercise_cols, drop = FALSE]), na.rm = TRUE)
    }, numeric(1)),
    stringsAsFactors = FALSE
  )
  scores$student <- factor(scores$student, levels = scores$student[order(scores$score)])

  heat <- as.data.frame(results, format = "long")
  agg <- aggregate(
    status ~ student + exercise,
    data = heat,
    FUN = function(s) {
      s <- as.character(s)
      if ("source_error" %in% s) "source_error"
      else if ("missing" %in% s) "missing"
      else if ("timeout" %in% s) "timeout"
      else if ("error" %in% s) "error"
      else if (all(s == "pass")) "pass"
      else "fail"
    }
  )

  p1 <- ggplot2::ggplot(scores, ggplot2::aes(x = .data$score, y = .data$student, fill = .data$score >= 0.5)) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = c("FALSE" = "#f8d7da", "TRUE" = "#d4edda"), guide = "none") +
    ggplot2::geom_vline(xintercept = mean(scores$score, na.rm = TRUE), linetype = "dashed", color = "gray40") +
    ggplot2::labs(title = "Score by student", x = "Score", y = NULL) +
    ggplot2::xlim(0, 1)

  p2 <- ggplot2::ggplot(pass_rate, ggplot2::aes(x = .data$exercise, y = .data$pass_rate, fill = .data$pass_rate >= 0.5)) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(values = c("FALSE" = "#f8d7da", "TRUE" = "#d4edda"), guide = "none") +
    ggplot2::geom_hline(yintercept = mean(pass_rate$pass_rate, na.rm = TRUE), linetype = "dashed", color = "gray40") +
    ggplot2::labs(title = "Pass rate by exercise", x = NULL, y = "Pass rate") +
    ggplot2::ylim(0, 1) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  status_colors <- c(
    pass        = "#d4edda",
    fail        = "#f8d7da",
    error       = "#fff3cd",
    timeout     = "#ffe5b4",
    missing     = "#e9ecef",
    source_error = "#f5b7b1"
  )
  p3 <- ggplot2::ggplot(agg, ggplot2::aes(x = .data$exercise, y = .data$student, fill = .data$status)) +
    ggplot2::geom_tile(color = "white") +
    ggplot2::scale_fill_manual(values = status_colors) +
    ggplot2::labs(title = "Results heatmap", x = NULL, y = NULL, fill = "Status") +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  print(p1); print(p2); print(p3)
}
