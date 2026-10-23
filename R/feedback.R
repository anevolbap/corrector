#' Escribir un archivo de devolución por estudiante
#'
#' Escribe `<student>.md` en `dir` para cada estudiante: el puntaje total, el
#' puntaje de cada ejercicio y el estado de cada test, con el mensaje de error
#' cuando lo hay. Usala para mandarle a cada estudiante sus resultados.
#'
#' @section English:
#' **Write one feedback file per student.** Writes `<student>.md` into `dir`
#' for every student: the total score, the score of each exercise, and the
#' status of each test, with the error message when there is one. Use it to
#' send each student their results.
#'
#' @param results Un objeto [grade_results].
#'   *English:* A [grade_results] object.
#' @param dir Carpeta donde escribir. Se crea si hace falta.
#'   *English:* Folder to write into. Created if needed.
#' @param scoring,weights Se pasan a [student_scores()].
#'   *English:* Passed to [student_scores()].
#' @param lang Idioma de los archivos: `"es"` o `"en"`. Por defecto sigue el
#'   idioma de la computadora (`LANGUAGE` o la configuración regional): inglés
#'   si es inglés, castellano en cualquier otro caso.
#'   *English:* Language of the files: `"es"` or `"en"`. By default it follows
#'   the computer's language (`LANGUAGE` or the locale): English if that is
#'   English, Spanish otherwise.
#' @return Las rutas de los archivos escritos, de forma invisible.
#'   *English:* The paths of the written files, invisibly.
#' @export
#' @examples
#' dir <- file.path(tempdir(), "feedback")
#' paths <- export_feedback(example_results(), dir)
#' writeLines(readLines(paths[[1]]))
export_feedback <- function(results, dir, scoring = c("partial", "all"),
                            weights = NULL, lang = default_lang()) {
  results <- ensure_grade_results(results)
  lang <- match.arg(lang, c("es", "en"))
  labels <- feedback_labels[[lang]]
  scores <- student_scores(results, scoring = match.arg(scoring), weights = weights)
  exercises <- setdiff(names(scores), c("student", "total"))
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  pct <- function(v) if (is.na(v)) labels$not_graded else sprintf("%.0f%%", v * 100)

  # Safe file names; students whose safe names collide get a numeric suffix.
  file_names <- make.unique(gsub("[/\\\\:*?\"<>|]", "_", scores$student), sep = "_")
  paths <- vapply(seq_len(nrow(scores)), function(i) {
    student <- scores$student[[i]]
    lines <- c(paste0("# ", student), "",
               paste0(labels$total, ": ", pct(scores$total[[i]])), "")
    for (ex in exercises) {
      rows <- results[results$student %in% student & results$exercise == ex, , drop = FALSE]
      lines <- c(lines, paste0("## ", ex, ": ", pct(scores[[ex]][[i]])), "")
      for (j in seq_len(nrow(rows))) {
        label <- if (is.na(rows$test[[j]])) ex else rows$test[[j]]
        lines <- c(lines, sprintf("- `%s`: %s", label,
                                  labels$status[[as.character(rows$status[[j]])]]))
        if (!is.na(rows$message[[j]])) {
          lines <- c(lines, "", "  ```", paste0("  ", strsplit(rows$message[[j]], "\n")[[1]]),
                     "  ```", "")
        }
      }
      lines <- c(lines, "")
    }
    path <- file.path(dir, paste0(file_names[[i]], ".md"))
    writeLines(lines, path, useBytes = TRUE)
    path
  }, character(1))
  invisible(paths)
}

# Text of the feedback files. Students read these, so they come in Spanish
# and English; everything else corrector prints stays in English.
feedback_labels <- list(
  es = list(
    total = "Nota total", not_graded = "sin corregir",
    status = c(pass = "aprobado", fail = "no aprobado", error = "error",
               timeout = "tiempo agotado", missing = "no entregado",
               source_error = "error al cargar el archivo")
  ),
  en = list(
    total = "Total score", not_graded = "not graded",
    status = c(pass = "pass", fail = "fail", error = "error",
               timeout = "timeout", missing = "missing",
               source_error = "source_error")
  )
)

# "en" when the computer's language is English, "es" otherwise.
default_lang <- function() {
  language <- Sys.getenv("LANGUAGE")
  lang_of(if (nzchar(language)) language else Sys.getlocale("LC_COLLATE"))
}

# Language code for a LANGUAGE value or locale name, e.g. "en_US.UTF-8" or
# "English_United States.1252" (Windows).
lang_of <- function(x) {
  if (grepl("^(en([_.@:-]|$)|english)", x, ignore.case = TRUE)) "en" else "es"
}
