#' Grade a single exercise file against its tests
#'
#' Sources the student's file and the matching test file into an isolated
#' environment, then runs every function whose name matches
#' `test_<stem>_*` and returns the results as a named logical vector.
#'
#' @param file Path to the student's R file (e.g. `"ejercicio1.R"`).
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function. Tests that exceed
#'   this limit are recorded as `FALSE`. Default `Inf` (no limit).
#' @return Named logical vector with one element per test function.
#'   Returns `c(source_error = FALSE)` if the student file cannot be sourced.
#'   Returns `logical(0)` with a warning if no matching test file is found.
#' @export
grade_exercise <- function(file, test_dir, timeout = Inf) {
  env <- new.env(parent = baseenv())

  test_file <- find_test_file(file, test_dir)
  if (is.null(test_file)) {
    warning("No test file found for: ", basename(file))
    return(logical(0))
  }

  ok <- tryCatch({
    source(file, local = env)
    TRUE
  }, error = function(e) {
    warning("Failed to source ", basename(file), ": ", conditionMessage(e))
    FALSE
  })

  if (!ok) return(c(source_error = FALSE))

  source(test_file, local = env)

  stem <- tools::file_path_sans_ext(basename(file))
  test_fns <- ls(envir = env, pattern = paste0("^test_", stem, "_"))

  sapply(test_fns, function(fn) {
    run_with_timeout(get(fn, envir = env), timeout)
  })
}

#' Grade all student submissions in a directory or zip archive
#'
#' Expects one sub-folder per student inside `submissions_path`. Each
#' sub-folder may contain one or more R files whose names contain
#' `"ejercicio"`. Each file is graded with [grade_exercise()] and collapsed to
#' a single pass/fail value (all tests passed).
#'
#' If `submissions_path` ends in `.zip` it is extracted first into a directory
#' with the same base name.
#'
#' @param submissions_path Path to a directory or `.zip` archive of submissions.
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function, passed to
#'   [grade_exercise()]. Default `Inf` (no limit).
#' @return Data frame with one row per student (column `student`) and one
#'   logical column per exercise (`TRUE` = all tests passed).
#' @export
grade_submissions <- function(submissions_path, test_dir, timeout = Inf) {
  dir <- extract_if_zip(submissions_path)
  students <- list.files(dir)

  rows <- lapply(students, function(student) {
    name <- student_name(student)
    message("Grading: ", name)

    exercise_files <- list.files(
      file.path(dir, student),
      pattern = "ejercicio",
      full.names = TRUE
    )

    grades <- lapply(exercise_files, grade_exercise, test_dir = test_dir, timeout = timeout)
    passed <- sapply(grades, function(r) length(r) > 0 && all(r))
    names(passed) <- tools::file_path_sans_ext(basename(exercise_files))

    as.data.frame(c(list(student = name), as.list(passed)))
  })

  do.call(rbind, rows)
}

# ---------- internal helpers ----------

find_test_file <- function(file, test_dir) {
  target <- paste0("test_", basename(file))
  matches <- list.files(test_dir, full.names = TRUE)
  hit <- matches[basename(matches) == target]
  if (length(hit) == 0) NULL else hit[[1]]
}

extract_if_zip <- function(path) {
  if (identical(tolower(tools::file_ext(path)), "zip")) {
    dest <- file.path(tempdir(), paste0("corrector_", basename(tools::file_path_sans_ext(path))))
    unlink(dest, recursive = TRUE)
    dir.create(dest, recursive = TRUE)
    unzip(path, exdir = dest)
    return(dest)
  }
  path
}

run_with_timeout <- function(fn, timeout) {
  setTimeLimit(elapsed = timeout, transient = FALSE)
  on.exit(setTimeLimit(elapsed = Inf, transient = FALSE))
  tryCatch(fn(), error = function(e) FALSE)
}

# Convention: folder names like "apellido_nombre_..." or just "apellido"
student_name <- function(folder) {
  parts <- strsplit(folder, "_")[[1]]
  tools::toTitleCase(tolower(parts[[1]]))
}
