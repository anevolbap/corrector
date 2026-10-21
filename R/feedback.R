#' Write one feedback file per student
#'
#' Writes `<student>.md` into `dir` for every student: the total score, the
#' score of each exercise, and the status of each test, with the error
#' message when there is one. Use it to send each student their results.
#'
#' @param results A [grade_results] object.
#' @param dir Folder to write into. Created if needed.
#' @param scoring,weights Passed to [student_scores()].
#' @return The paths of the written files, invisibly.
#' @export
#' @examples
#' dir <- file.path(tempdir(), "feedback")
#' paths <- export_feedback(example_results(), dir)
#' writeLines(readLines(paths[[1]]))
export_feedback <- function(results, dir, scoring = c("partial", "all"),
                            weights = NULL) {
  results <- ensure_grade_results(results)
  scores <- student_scores(results, scoring = match.arg(scoring), weights = weights)
  exercises <- setdiff(names(scores), c("student", "total"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  pct <- function(v) if (is.na(v)) "not graded" else sprintf("%.0f%%", v * 100)

  paths <- vapply(seq_len(nrow(scores)), function(i) {
    student <- scores$student[[i]]
    lines <- c(paste0("# ", student), "",
               paste0("Total score: ", pct(scores$total[[i]])), "")
    for (ex in exercises) {
      rows <- results[results$student == student & results$exercise == ex, , drop = FALSE]
      lines <- c(lines, paste0("## ", ex, ": ", pct(scores[[ex]][[i]])), "")
      for (j in seq_len(nrow(rows))) {
        label <- if (is.na(rows$test[[j]])) ex else rows$test[[j]]
        lines <- c(lines, sprintf("- `%s`: %s", label, as.character(rows$status[[j]])))
        if (!is.na(rows$message[[j]])) {
          lines <- c(lines, "", "  ```", paste0("  ", strsplit(rows$message[[j]], "\n")[[1]]),
                     "  ```", "")
        }
      }
      lines <- c(lines, "")
    }
    path <- file.path(dir, paste0(gsub("[/\\\\:*?\"<>|]", "_", student), ".md"))
    writeLines(lines, path, useBytes = TRUE)
    path
  }, character(1))
  invisible(paths)
}
