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
