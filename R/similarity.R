#' Buscar entregas parecidas entre estudiantes
#'
#' Compara, para cada ejercicio, los archivos de todos los pares de
#' estudiantes y devuelve los pares con una similitud de al menos
#' `min_similarity`, del más parecido al menos parecido. Sirve para detectar
#' entregas copiadas.
#'
#' Cada archivo se convierte en una secuencia de elementos de R sin
#' comentarios ni espacios. Los nombres de variables, los textos y los números
#' se reemplazan por marcadores, así que cambiar nombres o el formato no
#' esconde una copia. Las llamadas a funciones conservan el nombre, salvo las
#' funciones que define el mismo archivo. La similitud es la proporción de
#' grupos de `k` elementos seguidos que comparten los dos archivos (índice de
#' Jaccard). Los ejercicios se reconocen por el nombre del archivo, sin
#' importar mayúsculas; se leen archivos `.R`, `.Rmd` y `.qmd`.
#'
#' Una similitud alta no prueba una copia: soluciones cortas o muy guiadas se
#' parecen naturalmente. Usala para elegir qué entregas mirar a mano.
#'
#' @section English:
#' **Find similar submissions between students.** For each exercise, compares
#' the files of every pair of students and returns the pairs with a similarity
#' of at least `min_similarity`, most similar first. Use it to spot copied
#' work.
#'
#' Each file becomes a sequence of R tokens without comments or spacing.
#' Variable names, strings and numbers are replaced by placeholders, so
#' renaming or reformatting does not hide a copy. Function calls keep their
#' names, except functions the file defines itself. The similarity is the
#' share of runs of `k` tokens that both files have (Jaccard index).
#' Exercises are matched by file name, ignoring case; `.R`, `.Rmd` and `.qmd`
#' files are read.
#'
#' A high similarity does not prove copying: short or guided solutions look
#' alike. Use it to pick which submissions to read by hand.
#'
#' @param submissions_path Carpeta o archivo `.zip` con las entregas, como en
#'   [grade_submissions()].
#'   *English:* Folder or `.zip` of submissions, as in [grade_submissions()].
#' @param layout `"folders"` o `"moodle"`, como en [grade_submissions()].
#'   *English:* `"folders"` or `"moodle"`, as in [grade_submissions()].
#' @param min_similarity Similitud mínima (entre 0 y 1) de los pares que se
#'   devuelven. Por defecto 0.7.
#'   *English:* Minimum similarity (between 0 and 1) of the returned pairs.
#'   Default 0.7.
#' @param student_name_fn Función para el nombre de cada estudiante, como en
#'   [grade_submissions()].
#'   *English:* Function for each student's name, as in [grade_submissions()].
#' @param k Largo de los grupos de elementos que se comparan. Valores más
#'   chicos encuentran más coincidencias. Por defecto 5.
#'   *English:* Length of the token runs that are compared. Smaller values
#'   find more matches. Default 5.
#' @return Un data frame con las columnas `exercise`, `student_a`,
#'   `student_b` y `similarity` (entre 0 y 1).
#'   *English:* A data frame with columns `exercise`, `student_a`,
#'   `student_b` and `similarity` (between 0 and 1).
#' @export
#' @examples
#' root <- file.path(tempdir(), "copias")
#' for (s in c("ana", "beto", "carla")) dir.create(file.path(root, s), recursive = TRUE)
#' writeLines("doble <- function(x) x * 2", file.path(root, "ana", "ejercicio1.R"))
#' writeLines("doble<-function(valor) valor*2  # mio", file.path(root, "beto", "ejercicio1.R"))
#' writeLines("doble <- function(x) x + x", file.path(root, "carla", "ejercicio1.R"))
#' compare_submissions(root, min_similarity = 0)
compare_submissions <- function(submissions_path, layout = c("folders", "moodle"),
                                min_similarity = 0.7,
                                student_name_fn = default_student_name, k = 5) {
  layout <- match.arg(layout)
  if (!file.exists(submissions_path)) {
    stop("submissions_path does not exist: ", submissions_path, call. = FALSE)
  }
  if (layout == "moodle" && missing(student_name_fn)) {
    student_name_fn <- moodle_student_name
  }
  found <- locate_students(submissions_path, layout)
  display <- display_names(found$students, student_name_fn)

  # One row per (student, file), keyed by exercise name.
  files <- do.call(rbind, lapply(seq_along(found$students), function(i) {
    paths <- list.files(file.path(found$dir, found$students[[i]]),
                        pattern = "\\.(r|rmd|qmd)$", ignore.case = TRUE,
                        full.names = TRUE)
    if (length(paths) == 0) return(NULL)
    data.frame(student = display[[i]], path = paths,
               exercise = tolower(tools::file_path_sans_ext(basename(paths))),
               stringsAsFactors = FALSE)
  }))

  out <- data.frame(exercise = character(), student_a = character(),
                    student_b = character(), similarity = numeric(),
                    stringsAsFactors = FALSE)
  if (is.null(files)) return(out)
  for (ex in unique(files$exercise)) {
    rows <- files[files$exercise == ex, , drop = FALSE]
    if (nrow(rows) < 2) next
    shingles <- lapply(rows$path, function(p) code_shingles(p, k))
    pairs <- utils::combn(nrow(rows), 2)
    sim <- apply(pairs, 2, function(ij) jaccard(shingles[[ij[1]]], shingles[[ij[2]]]))
    out <- rbind(out, data.frame(exercise = ex,
                                 student_a = rows$student[pairs[1, ]],
                                 student_b = rows$student[pairs[2, ]],
                                 similarity = sim, stringsAsFactors = FALSE))
  }
  out <- out[out$similarity >= min_similarity, , drop = FALSE]
  out <- out[order(-out$similarity, out$exercise), , drop = FALSE]
  rownames(out) <- NULL
  out
}

# Runs of k normalized tokens of a student file.
code_shingles <- function(path, k) {
  tokens <- tryCatch(code_tokens(r_code_path(path)), error = function(e) character())
  if (length(tokens) == 0) return(character())
  if (length(tokens) <= k) return(paste(tokens, collapse = " "))
  starts <- seq_len(length(tokens) - k + 1)
  unique(vapply(starts, function(s) paste(tokens[s:(s + k - 1)], collapse = " "),
                character(1)))
}

# Parse tokens with names, strings and numbers replaced by placeholders.
# Files that do not parse fall back to their words and symbols.
code_tokens <- function(path) {
  lines <- iconv(readLines(path, warn = FALSE), from = source_encoding(path),
                 to = "UTF-8", sub = "?")
  pd <- tryCatch(utils::getParseData(parse(text = lines, keep.source = TRUE)),
                 error = function(e) NULL)
  if (is.null(pd) || nrow(pd) == 0) {
    text <- gsub("#.*$", "", lines)
    words <- unlist(regmatches(text, gregexpr("[[:alnum:]._]+|[^[:alnum:]._[:space:]]", text)))
    return(ifelse(grepl("^[[:alpha:].]", words), "ID", words))
  }
  pd <- pd[pd$terminal & pd$token != "COMMENT", , drop = FALSE]
  pd <- pd[order(pd$line1, pd$col1), , drop = FALSE]
  # Functions defined in this file: a name right before `<-`, `=` or `<<-`
  # followed by `function`.
  defined <- character()
  for (i in which(pd$token == "FUNCTION")) {
    if (i > 2 && pd$token[i - 1] %in% c("LEFT_ASSIGN", "EQ_ASSIGN")) {
      defined <- c(defined, pd$text[i - 2])
    }
  }
  tok <- pd$text
  tok[pd$token %in% c("SYMBOL", "SYMBOL_FORMALS", "SYMBOL_SUB")] <- "ID"
  tok[pd$token == "STR_CONST"] <- "STR"
  tok[pd$token == "NUM_CONST"] <- "NUM"
  tok[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% defined] <- "ID"
  tok
}

jaccard <- function(a, b) {
  if (length(a) == 0 && length(b) == 0) return(1)
  length(intersect(a, b)) / length(union(a, b))
}
