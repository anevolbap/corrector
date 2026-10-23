#' Nombre del estudiante a partir de una carpeta de Moodle
#'
#' "Descargar todas las entregas" de Moodle nombra cada carpeta
#' `<Nombre completo>_<id>_assignsubmission_file`. Esta función se queda con
#' el nombre completo. Con calificación anónima (*blind marking*) todas las
#' carpetas empiezan con "Participante", así que los nombres se repiten y
#' [grade_submissions()] usa los nombres de las carpetas.
#'
#' @section English:
#' **Student name from a Moodle submission folder.** Moodle's "Download all
#' submissions" names each folder `<Full name>_<id>_assignsubmission_file`.
#' This keeps the full name. With blind marking every folder starts with
#' "Participant", so names clash and [grade_submissions()] falls back to the
#' folder names.
#'
#' @param folder Texto. Nombre de la carpeta de la entrega.
#'   *English:* Character. Submission folder name.
#' @return Texto. Nombre para mostrar.
#'   *English:* Character. Display name.
#' @export
#' @examples
#' moodle_student_name("Juan Perez_123456_assignsubmission_file")
moodle_student_name <- function(folder) {
  sub("_[^_]+_assignsubmission_.*$", "", folder)
}

#' Devoluciones en un .zip listo para subir a Moodle
#'
#' Escribe con [export_feedback()] un archivo de devolución por estudiante y
#' lo guarda en un `.zip`, dentro de la carpeta de Moodle de cada estudiante
#' (`<Nombre completo>_<id>_assignsubmission_file/devolucion.md`). En la
#' página de entregas de la tarea, usá la opción para subir varios archivos de
#' retroalimentación en un zip (en inglés, *Upload multiple feedback files in
#' a zip*); Moodle reconoce a cada estudiante por el número de la carpeta. La
#' tarea tiene que tener activada la retroalimentación con archivos.
#'
#' Los resultados tienen que venir de `grade_submissions(layout = "moodle")`,
#' que guarda los nombres de las carpetas.
#'
#' @section English:
#' **Feedback in a .zip ready to upload to Moodle.** Writes one feedback file
#' per student with [export_feedback()] and stores it in a `.zip`, inside each
#' student's Moodle folder
#' (`<Full name>_<id>_assignsubmission_file/feedback.md`). On the assignment's
#' submissions page, use "Upload multiple feedback files in a zip"; Moodle
#' matches each student by the number in the folder name. The assignment must
#' have file feedback turned on.
#'
#' The results must come from `grade_submissions(layout = "moodle")`, which
#' keeps the folder names.
#'
#' @param results Un objeto [grade_results] de
#'   `grade_submissions(layout = "moodle")`.
#'   *English:* A [grade_results] object from
#'   `grade_submissions(layout = "moodle")`.
#' @param zip_path Ruta del `.zip` que se escribe.
#'   *English:* Path of the `.zip` to write.
#' @param scoring,weights,lang Se pasan a [export_feedback()]. El archivo se
#'   llama `devolucion.md` con `lang = "es"` y `feedback.md` con `lang = "en"`.
#'   *English:* Passed to [export_feedback()]. The file is `devolucion.md` with
#'   `lang = "es"` and `feedback.md` with `lang = "en"`.
#' @return `zip_path`, de forma invisible.
#'   *English:* `zip_path`, invisibly.
#' @export
#' @examples
#' \dontrun{
#' resultados <- grade_submissions("tarea1.zip", test_dir = "tests/",
#'                                 layout = "moodle")
#' export_moodle_feedback(resultados, "devoluciones-tarea1.zip")
#' }
export_moodle_feedback <- function(results, zip_path,
                                   scoring = c("partial", "all"),
                                   weights = NULL, lang = default_lang()) {
  results <- ensure_grade_results(results)
  folders <- attr(results, "folders")
  is_moodle <- grepl("_[0-9]+_assign(submission|feedback)_", folders)
  if (is.null(folders) || !all(is_moodle) ||
      !all(unique(results$student) %in% names(folders))) {
    stop("export_moodle_feedback() needs results from ",
         "grade_submissions(layout = \"moodle\")", call. = FALSE)
  }
  lang <- match.arg(lang, c("es", "en"))
  file_name <- if (lang == "es") "devolucion.md" else "feedback.md"

  feedback <- export_feedback(results, tempfile("corrector_feedback"),
                              scoring = scoring, weights = weights, lang = lang)
  staging <- tempfile("corrector_moodle_zip")
  for (student in names(feedback)) {
    dest <- file.path(staging, folders[[student]])
    dir.create(dest, recursive = TRUE)
    file.copy(feedback[[student]], file.path(dest, file_name))
  }

  zip_path <- file.path(normalizePath(dirname(zip_path)), basename(zip_path))
  unlink(zip_path)
  old <- setwd(staging)
  on.exit(setwd(old), add = TRUE)
  utils::zip(zip_path, list.files(recursive = TRUE), flags = "-r9Xq")
  invisible(zip_path)
}

# Rebuilds a Moodle export as one folder per student, keeping only file
# submissions. Handles both the folder export and the flat one (Moodle's
# "Download submissions in folders" turned off).
moodle_to_folders <- function(dir) {
  out <- file.path(tempdir(), paste0("corrector_moodle_", basename(dir)))
  unlink(out, recursive = TRUE)
  dir.create(out, recursive = TRUE)
  folder_re <- "^(.+_assignsubmission_file)_?$"
  flat_re   <- "^(.+_assignsubmission_file)_(.+)$"
  for (entry in list.files(dir)) {
    path <- file.path(dir, entry)
    if (dir.exists(path) && grepl(folder_re, entry)) {
      dest <- file.path(out, sub(folder_re, "\\1", entry))
      dir.create(dest, showWarnings = FALSE)
      file.copy(list.files(path, full.names = TRUE), dest, recursive = TRUE)
    } else if (!dir.exists(path) && grepl(flat_re, entry)) {
      dest <- file.path(out, sub(flat_re, "\\1", entry))
      dir.create(dest, showWarnings = FALSE)
      file.copy(path, file.path(dest, sub(flat_re, "\\2", entry)))
    }
  }
  out
}
