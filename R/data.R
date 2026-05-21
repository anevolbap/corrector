#' Sample grading results
#'
#' A small fake [grade_results] object with 8 students and 5 exercises,
#' useful for trying out [grade_report()], [plot_report()], and the export
#' functions without needing real student submissions.
#'
#' @return A [grade_results] object.
#' @export
#' @examples
#' results <- example_results()
#' grade_report(results)
#' plot_report(results, ask = FALSE)
example_results <- function() {
  students <- c("Garcia", "Lopez", "Martinez", "Rodriguez",
                "Fernandez", "Gonzalez", "Perez", "Sanchez")
  pattern <- list(
    ejercicio1 = c(TRUE,  TRUE,  TRUE,  FALSE, TRUE,  TRUE,  FALSE, TRUE),
    ejercicio2 = c(TRUE,  TRUE,  FALSE, TRUE,  TRUE,  FALSE, TRUE,  TRUE),
    ejercicio3 = c(TRUE,  FALSE, TRUE,  TRUE,  TRUE,  TRUE,  FALSE, FALSE),
    ejercicio4 = c(FALSE, TRUE,  TRUE,  FALSE, FALSE, TRUE,  TRUE,  TRUE),
    ejercicio5 = c(TRUE,  TRUE,  TRUE,  TRUE,  FALSE, TRUE,  TRUE,  FALSE)
  )

  rows <- list()
  for (ex in names(pattern)) {
    for (i in seq_along(students)) {
      rows[[length(rows) + 1L]] <- data.frame(
        student  = students[[i]],
        exercise = ex,
        test     = paste0("test_", ex, "_case1"),
        status   = if (pattern[[ex]][[i]]) "pass" else "fail",
        message  = NA_character_,
        duration = 0,
        stringsAsFactors = FALSE
      )
    }
  }
  new_grade_results(do.call(rbind, rows))
}
