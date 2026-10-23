#' Puntaje de cada estudiante, con puntaje parcial y pesos opcionales
#'
#' @section English:
#' **Score each student, with optional partial credit and weights.**
#'
#' @param results Un objeto [grade_results].
#'   *English:* A [grade_results] object.
#' @param scoring `"partial"` (por defecto): el puntaje de un ejercicio es la
#'   fracción ponderada de sus tests que pasan. `"all"`: un ejercicio vale 1
#'   solo si pasan todos sus tests, si no vale 0.
#'   *English:* `"partial"` (default): an exercise scores the weighted
#'   fraction of its tests that pass. `"all"`: an exercise scores 1 only if
#'   every test passes, else 0.
#' @param weights Vector numérico con nombres, opcional. Un nombre que
#'   coincide con una función de test (por ejemplo `test_ejercicio1_raices`)
#'   define el peso de ese test dentro de su ejercicio. Un nombre que coincide
#'   con un ejercicio (por ejemplo `ejercicio1`) define el peso de ese
#'   ejercicio en `total`. Lo que no aparece en el vector pesa 1.
#'   *English:* Optional named numeric vector. A name that matches a test
#'   function (e.g. `test_ejercicio1_raices`) weights that test inside its
#'   exercise. A name that matches an exercise (e.g. `ejercicio1`) weights
#'   that exercise in `total`. Anything not named weighs 1.
#' @return Un data frame con una fila por estudiante: una columna `student`,
#'   una columna numérica (0-1) por ejercicio y `total`. Un ejercicio vale `NA`
#'   cuando está `missing` o tiene un `source_error`; en `total` cuenta como 0.
#'   *English:* A data frame with one row per student: a `student` column, one
#'   numeric column (0-1) per exercise, and `total`. An exercise is `NA` when
#'   it is `missing` or has a `source_error`; it counts as 0 in `total`.
#' @export
#' @examples
#' results <- example_results()
#' student_scores(results)
#' student_scores(results, weights = c(ejercicio5 = 2))
student_scores <- function(results, scoring = c("partial", "all"), weights = NULL) {
  results <- ensure_grade_results(results)
  scoring <- match.arg(scoring)
  if (is.null(weights)) weights <- numeric()
  unknown <- setdiff(names(weights),
                     c(results$exercise, results$test[!is.na(results$test)]))
  if (length(unknown) > 0) {
    warning("Names in weights match no test or exercise: ",
            paste(unknown, collapse = ", "))
  }
  weight_of <- function(nms) {
    w <- unname(weights[nms])
    w[is.na(w)] <- 1
    w
  }

  reserved <- intersect(unique(results$exercise), c("student", "total"))
  if (length(reserved) > 0) {
    stop("Exercise names clash with output columns: ",
         paste(reserved, collapse = ", "), ". Rename the test files.",
         call. = FALSE)
  }

  students  <- unique(results$student)
  exercises <- unique(results$exercise)
  out <- data.frame(student = students, stringsAsFactors = FALSE)
  for (ex in exercises) {
    out[[ex]] <- vapply(students, function(st) {
      rows <- results[results$student %in% st & results$exercise == ex, , drop = FALSE]
      if (nrow(rows) == 0) return(NA_real_)
      if (any(rows$status %in% c("missing", "source_error"))) return(NA_real_)
      pass <- rows$status == "pass"
      if (scoring == "all") return(as.numeric(all(pass)))
      w <- weight_of(rows$test)
      sum(w * pass) / sum(w)
    }, numeric(1), USE.NAMES = FALSE)
  }

  scores <- as.matrix(out[exercises])
  scores[is.na(scores)] <- 0
  ew <- weight_of(exercises)
  out$total <- as.vector(scores %*% ew) / sum(ew)
  out
}
