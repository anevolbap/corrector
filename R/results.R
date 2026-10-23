#' Objeto con los resultados de la corrección
#'
#' Un objeto `grade_results` es un data frame en formato largo con una fila
#' por (estudiante, ejercicio, test) y estas columnas:
#' \describe{
#'   \item{`student`}{Texto. Nombre del estudiante para mostrar.}
#'   \item{`exercise`}{Texto. Identificador del ejercicio (nombre del archivo
#'     sin extensión).}
#'   \item{`test`}{Texto. Nombre de la función de test, o `NA` cuando la fila
#'     registra una entrega `missing` o un `source_error`.}
#'   \item{`status`}{Factor con niveles `pass`, `fail`, `error`, `timeout`,
#'     `missing`, `source_error`.}
#'   \item{`message`}{Texto. El mensaje de error para `error`,
#'     `source_error` y `timeout`; el mensaje de testthat o "test returned
#'     non-logical" para algunas filas `fail`; una nota con las definiciones
#'     del estudiante que se ignoraron (ver `allow_masking` en
#'     [grade_exercise()]); `NA` en los demás casos.}
#'   \item{`duration`}{Numérico. Segundos que tardó el test, o `NA` cuando el
#'     test no se ejecutó.}
#' }
#'
#' Usá [as.data.frame()] con `format = "wide"` para obtener la vista anterior
#' en formato ancho (una columna lógica por ejercicio, `TRUE` si y solo si
#' pasaron todos los tests).
#'
#' @section English:
#' **Grading results object.** A `grade_results` object is a data frame in
#' long format with one row per (student, exercise, test) and the following
#' columns:
#' \describe{
#'   \item{`student`}{Character. Student display name.}
#'   \item{`exercise`}{Character. Exercise identifier (file stem).}
#'   \item{`test`}{Character. Test function name, or `NA` when the row
#'     records a `missing` submission or a `source_error`.}
#'   \item{`status`}{Factor with levels `pass`, `fail`, `error`, `timeout`,
#'     `missing`, `source_error`.}
#'   \item{`message`}{Character. The error message for `error`,
#'     `source_error` and `timeout`; the testthat message or "test returned
#'     non-logical" for some `fail` rows; a note listing ignored student
#'     definitions (see `allow_masking` in [grade_exercise()]); `NA`
#'     otherwise.}
#'   \item{`duration`}{Numeric. Seconds elapsed running the test, or `NA`
#'     when the test was not run.}
#' }
#'
#' Use [as.data.frame()] with `format = "wide"` to get the old wide-boolean
#' view (one logical column per exercise, `TRUE` iff all tests passed).
#'
#' @name grade_results
NULL

status_levels <- c("pass", "fail", "error", "timeout", "missing", "source_error")

new_grade_results <- function(df) {
  stopifnot(is.data.frame(df))
  expected <- c("student", "exercise", "test", "status", "message", "duration")
  missing_cols <- setdiff(expected, names(df))
  if (length(missing_cols) > 0) {
    stop("grade_results is missing columns: ",
         paste(missing_cols, collapse = ", "))
  }
  df <- df[expected]
  if (!is.factor(df$status)) {
    df$status <- factor(df$status, levels = status_levels)
  }
  structure(df, class = c("grade_results", "data.frame"))
}

empty_grade_results <- function() {
  new_grade_results(data.frame(
    student  = character(),
    exercise = character(),
    test     = character(),
    status   = factor(character(), levels = status_levels),
    message  = character(),
    duration = numeric(),
    stringsAsFactors = FALSE
  ))
}

#' @export
print.grade_results <- function(x, ...) {
  cat(sprintf("<grade_results> %d rows, %d students, %d exercises\n",
              nrow(x),
              length(unique(x$student)),
              length(unique(x$exercise))))
  if (nrow(x) == 0) return(invisible(x))
  counts <- table(x$status)
  cat("Status:\n")
  for (lvl in names(counts)) {
    if (counts[[lvl]] > 0) {
      cat(sprintf("  %-13s %d\n", lvl, counts[[lvl]]))
    }
  }
  invisible(x)
}

#' Convertir los resultados de la corrección en un data frame
#'
#' @section English:
#' **Convert grading results to a data frame.**
#'
#' @param x Un objeto `grade_results`.
#'   *English:* A `grade_results` object.
#' @param row.names Se ignora. *English:* Ignored.
#' @param optional Se ignora. *English:* Ignored.
#' @param format `"long"` devuelve el data frame en formato largo que guarda
#'   el objeto. `"wide"` devuelve la vista anterior: una fila por estudiante,
#'   una columna lógica por ejercicio (`TRUE` si y solo si pasaron todos los
#'   tests; `NA` para `missing` o `source_error`).
#'   *English:* `"long"` returns the underlying long-format data frame.
#'   `"wide"` returns the legacy view: one row per student, one logical column
#'   per exercise (`TRUE` iff all tests passed; `NA` for `missing` or
#'   `source_error`).
#' @param ... Se ignora. *English:* Ignored.
#' @return Un data frame común.
#'   *English:* A plain data frame.
#' @export
#' @examples
#' results <- example_results()
#' head(as.data.frame(results))
#' as.data.frame(results, format = "wide")
as.data.frame.grade_results <- function(x, row.names = NULL, optional = FALSE,
                                        format = c("long", "wide"), ...) {
  format <- match.arg(format)
  long <- unclass(x)
  attr(long, "class") <- "data.frame"
  if (format == "long") return(long)

  students  <- unique(x$student)
  exercises <- unique(x$exercise)
  wide <- data.frame(student = students, stringsAsFactors = FALSE)
  for (ex in exercises) {
    wide[[ex]] <- vapply(students, function(st) {
      rows <- x[x$student %in% st & x$exercise == ex, , drop = FALSE]
      if (nrow(rows) == 0) return(NA)
      if (any(rows$status %in% c("missing", "source_error"))) return(NA)
      all(rows$status == "pass")
    }, logical(1))
  }
  wide
}
