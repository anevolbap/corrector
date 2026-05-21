#' Grade a single exercise file against its tests
#'
#' Sources the student's file and the matching test file into an isolated
#' environment, runs every function whose name matches the test pattern, and
#' returns the per-test outcome as a [grade_results] object.
#'
#' @param file Path to the student's R file (e.g. `"ejercicio1.R"`).
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function. Tests that exceed
#'   this limit are recorded with status `timeout`. Default `Inf`.
#' @param student Optional student display name. Defaults to `NA`.
#' @return A [grade_results] object with one row per test. If the student file
#'   fails to parse, one row with `status = source_error`. If no matching test
#'   file is found, one row with `status = missing` and a warning.
#' @export
grade_exercise <- function(file, test_dir, timeout = Inf, student = NA_character_) {
  exercise <- tools::file_path_sans_ext(basename(file))
  test_file <- find_test_file(file, test_dir)

  if (is.null(test_file)) {
    warning("No test file found for: ", basename(file))
    return(new_grade_results(data.frame(
      student  = student,
      exercise = exercise,
      test     = NA_character_,
      status   = "missing",
      message  = "no matching test file",
      duration = NA_real_,
      stringsAsFactors = FALSE
    )))
  }

  env <- new.env(parent = baseenv())
  src <- tryCatch({
    source(file, local = env)
    list(ok = TRUE)
  }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))

  if (!isTRUE(src$ok)) {
    warning("Failed to source ", basename(file), ": ", src$message)
    return(new_grade_results(data.frame(
      student  = student,
      exercise = exercise,
      test     = NA_character_,
      status   = "source_error",
      message  = src$message,
      duration = NA_real_,
      stringsAsFactors = FALSE
    )))
  }

  source(test_file, local = env)
  prefix <- paste0("test_", exercise, "_")
  test_fns <- ls(envir = env)
  test_fns <- test_fns[startsWith(test_fns, prefix)]

  if (length(test_fns) == 0) {
    return(empty_grade_results())
  }

  rows <- lapply(test_fns, function(fn) {
    out <- run_one_test(get(fn, envir = env), timeout)
    data.frame(
      student  = student,
      exercise = exercise,
      test     = fn,
      status   = out$status,
      message  = out$message,
      duration = out$duration,
      stringsAsFactors = FALSE
    )
  })
  new_grade_results(do.call(rbind, rows))
}

#' Grade all student submissions in a directory or zip archive
#'
#' Expects one sub-folder per student inside `submissions_path`. Every student
#' is graded on every exercise that has a test file in `test_dir`; a student
#' who omits an exercise gets a `missing` row.
#'
#' If `submissions_path` ends in `.zip` it is extracted into a `tempdir()`
#' subfolder first.
#'
#' @param submissions_path Path to a directory or `.zip` archive of submissions.
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function. Default `Inf`.
#' @return A [grade_results] object.
#' @importFrom utils unzip
#' @export
grade_submissions <- function(submissions_path, test_dir, timeout = Inf) {
  dir <- extract_if_zip(submissions_path)
  students <- list.files(dir)

  exercises <- expected_exercises(test_dir)
  if (length(exercises) == 0) {
    warning("No test files found in: ", test_dir)
    return(empty_grade_results())
  }

  slices <- lapply(students, function(student) {
    name <- student_name(student)
    message("Grading: ", name)

    per_student <- lapply(exercises, function(ex) {
      file <- file.path(dir, student, paste0(ex, ".R"))
      if (!file.exists(file)) {
        return(new_grade_results(data.frame(
          student  = name,
          exercise = ex,
          test     = NA_character_,
          status   = "missing",
          message  = "no submission",
          duration = NA_real_,
          stringsAsFactors = FALSE
        )))
      }
      grade_exercise(file, test_dir = test_dir, timeout = timeout, student = name)
    })
    do.call(rbind, lapply(per_student, unclass_df))
  })

  combined <- do.call(rbind, slices)
  new_grade_results(combined)
}

# ---------- internal helpers ----------

run_one_test <- function(fn, timeout) {
  t0 <- Sys.time()
  on.exit(setTimeLimit(elapsed = Inf, transient = FALSE), add = TRUE)
  if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)

  out <- tryCatch(
    list(value = fn(), err = NULL),
    error = function(e) list(value = NULL, err = e)
  )
  duration <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  if (!is.null(out$err)) {
    msg <- conditionMessage(out$err)
    is_timeout <- grepl("elapsed time limit|CPU time limit", msg)
    return(list(
      status   = if (is_timeout) "timeout" else "error",
      message  = msg,
      duration = duration
    ))
  }
  if (isTRUE(out$value)) {
    return(list(status = "pass", message = NA_character_, duration = duration))
  }
  if (isFALSE(out$value)) {
    return(list(status = "fail", message = NA_character_, duration = duration))
  }
  list(
    status   = "fail",
    message  = paste0("test returned non-logical: ", class(out$value)[[1]]),
    duration = duration
  )
}

find_test_file <- function(file, test_dir) {
  target <- paste0("test_", basename(file))
  matches <- list.files(test_dir, full.names = TRUE)
  hit <- matches[basename(matches) == target]
  if (length(hit) == 0) NULL else hit[[1]]
}

expected_exercises <- function(test_dir) {
  files <- list.files(test_dir, pattern = "^test_.+\\.R$", full.names = FALSE)
  stems <- tools::file_path_sans_ext(files)
  sub("^test_", "", stems)
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

# Convention: folder names like "apellido_nombre_..." or just "apellido"
student_name <- function(folder) {
  parts <- strsplit(folder, "_")[[1]]
  tools::toTitleCase(tolower(parts[[1]]))
}

unclass_df <- function(x) {
  attr(x, "class") <- "data.frame"
  x
}
