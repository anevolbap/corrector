#' Grade a single exercise file against its tests
#'
#' Sources the student's file and the matching test file into an isolated
#' environment, runs every function whose name starts with
#' `test_<exercise>_`, and returns the per-test outcome as a [grade_results]
#' object.
#'
#' A test passes if it returns `TRUE`. Tests can also use \pkg{testthat}
#' expectations (call `library(testthat)` at the top of the test file): the
#' test passes when at least one expectation succeeds and none fails, and a
#' failed expectation is recorded as `fail` with its message.
#'
#' @param file Path to the student's file: an R script (e.g. `"ejercicio1.R"`)
#'   or an R Markdown or Quarto document (`.Rmd`, `.qmd`), whose R chunks are
#'   extracted with `knitr::purl()`. The matching test file is found ignoring
#'   case.
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function. Tests that exceed
#'   this limit are recorded with status `timeout`. Default 10. Use `Inf` for
#'   no limit.
#' @param student Optional student display name. Defaults to `NA`.
#' @param engine `"callr"` (default) runs each exercise in a fresh R
#'   subprocess via the \pkg{callr} package, with a temporary working
#'   directory. The timeout is a hard wall-clock limit, and assignments with
#'   `<<-` or files the student writes do not reach your session or folder.
#'   `"inproc"` runs tests in the current R session. It is faster, but its
#'   `setTimeLimit()` timeout does not interrupt every kind of loop, and
#'   student code can see and change your global environment.
#' @param allow_masking Character vector of function names from base R and
#'   the default packages (stats, utils, methods, graphics, grDevices) that
#'   the student may redefine, e.g. `"factorial"` when the exercise asks for
#'   it. Any other student object with such a name is not visible to the
#'   tests, so a student cannot pass by redefining `all()` or `==`. Ignored
#'   names are listed in the `message` column.
#' @return A [grade_results] object with one row per test. If the student file
#'   fails to parse, one row with `status = source_error`. If no matching test
#'   file is found, one row with `status = missing` and a warning.
#' @export
#' @examples
#' # The package ships test files for five sample exercises.
#' tests <- system.file("examples", package = "corrector")
#' file <- file.path(tempdir(), "ejercicio1.R")
#' writeLines(c(
#'   "ceros_cuadratica <- function(a, b, c) {",
#'   "  d <- sqrt(b^2 - 4 * a * c)",
#'   "  c((-b - d) / (2 * a), (-b + d) / (2 * a))",
#'   "}"
#' ), file)
#' grade_exercise(file, tests, student = "Garcia")
grade_exercise <- function(file, test_dir, timeout = 10,
                           student = NA_character_,
                           engine = c("callr", "inproc"),
                           allow_masking = character()) {
  engine <- match.arg(engine)
  protected <- setdiff(protected_names(), allow_masking)
  exercise <- tools::file_path_sans_ext(basename(file))
  test_file <- find_test_file(exercise, test_dir)

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
  # Use the test file's spelling ("Ejercicio1.R" is graded as ejercicio1).
  exercise <- test_exercise(test_file)

  if (engine == "callr") {
    job <- start_grading_callr(file, test_file, timeout, student, protected)
    if (inherits(job, "grade_results")) return(job)
    job$proc$wait(timeout = wait_ms(job))
    return(finish_grading_callr(job))
  }

  test_fns <- discover_test_fns(test_file, exercise)

  student_env <- new.env(parent = globalenv())
  src <- tryCatch({
    code <- r_code_path(file)
    source(code, local = student_env, encoding = source_encoding(code))
    list(ok = TRUE)
  }, error = function(e) list(ok = FALSE, message = conditionMessage(e)))

  if (!isTRUE(src$ok)) {
    warning("Failed to source ", basename(file), ": ", src$message)
    return(source_error_result(student, exercise, src$message))
  }

  # Tests run in their own environment. Student objects are copied in, except
  # those that would mask a protected function the tests rely on.
  env <- new.env(parent = globalenv())
  masked <- copy_student_objects(student_env, env, protected)
  source(test_file, local = env, encoding = source_encoding(test_file))

  if (length(test_fns) == 0) {
    return(empty_grade_results())
  }

  rows <- lapply(test_fns, function(fn) {
    out <- run_one_test_inproc(get(fn, envir = env), timeout)
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
  new_grade_results(add_masking_note(do.call(rbind, rows), masked))
}

#' Grade all student submissions in a directory or zip archive
#'
#' Expects one sub-folder per student inside `submissions_path`. Every student
#' is graded on every exercise that has a test file in `test_dir`; a student
#' who omits an exercise gets a `missing` row. The student's file is matched
#' ignoring case (`Ejercicio1.R` counts as `ejercicio1`), and `.Rmd` or `.qmd`
#' files are accepted when there is no `.R` file.
#'
#' If `submissions_path` ends in `.zip` it is extracted into a `tempdir()`
#' subfolder first. Loose files, hidden folders and `__MACOSX` are ignored.
#' If the path holds a single folder with no `.R` files but with sub-folders,
#' those sub-folders are taken as the students.
#'
#' @param submissions_path Path to a directory or `.zip` archive of submissions.
#' @param test_dir Directory that contains the test files.
#' @param timeout Maximum seconds allowed per test function. Default 10.
#' @param engine `"callr"` (default) or `"inproc"`. See [grade_exercise()].
#' @param student_name_fn Function applied to each student folder name to
#'   produce the display name. Defaults to taking the first underscore-
#'   separated token and applying title case. Folders that map to the same
#'   name keep their folder name, with a warning.
#' @param allow_masking Base function names students may redefine. See
#'   [grade_exercise()].
#' @param layout `"folders"` (default): one folder per student. `"moodle"`:
#'   the zip or folder from Moodle's "Download all submissions", with or
#'   without "Download submissions in folders". Only file submissions are
#'   graded, and `student_name_fn` defaults to [moodle_student_name()].
#' @param workers Number of callr subprocesses to run at the same time.
#'   Default 1. Values above 1 speed up large classes; a value near
#'   `parallel::detectCores()` is a good upper bound. Ignored by the
#'   `"inproc"` engine.
#' @return A [grade_results] object.
#' @importFrom utils unzip
#' @export
#' @examples
#' # One folder per student, one test file per exercise.
#' root <- file.path(tempdir(), "entregas")
#' dir.create(file.path(root, "garcia_juan"), recursive = TRUE)
#' dir.create(file.path(root, "lopez_maria"), recursive = TRUE)
#' writeLines("ceros_cuadratica <- function(a, b, c) c(-1, 1)",
#'            file.path(root, "garcia_juan", "ejercicio1.R"))
#' writeLines("ceros_cuadratica <- function(a, b, c) 0",
#'            file.path(root, "lopez_maria", "ejercicio1.R"))
#' tests <- file.path(tempdir(), "tests")
#' dir.create(tests)
#' file.copy(system.file("examples", "test_ejercicio1.R", package = "corrector"),
#'           tests)
#' results <- grade_submissions(root, tests)
#' results
#' as.data.frame(results, format = "wide")
grade_submissions <- function(submissions_path, test_dir, timeout = 10,
                              engine = c("callr", "inproc"),
                              student_name_fn = default_student_name,
                              allow_masking = character(),
                              workers = 1L,
                              layout = c("folders", "moodle")) {
  engine <- match.arg(engine)
  layout <- match.arg(layout)
  stopifnot(length(workers) == 1, workers >= 1)
  dir <- extract_if_zip(submissions_path)
  if (layout == "moodle") {
    dir <- moodle_to_folders(dir)
    if (missing(student_name_fn)) student_name_fn <- moodle_student_name
  }
  students <- student_dirs(dir)
  # A zip of the parent folder holds one folder with the student folders inside.
  if (length(students) == 1 &&
      length(list.files(file.path(dir, students), pattern = "\\.R$")) == 0 &&
      length(student_dirs(file.path(dir, students))) > 0) {
    dir <- file.path(dir, students)
    students <- student_dirs(dir)
  }

  exercises <- expected_exercises(test_dir)
  if (length(exercises) == 0) {
    warning("No test files found in: ", test_dir)
    return(empty_grade_results())
  }

  use_cli <- requireNamespace("cli", quietly = TRUE) && length(students) > 1
  progress_id <- if (use_cli) {
    cli::cli_progress_bar("Grading", total = length(students), clear = FALSE,
                          .auto_close = FALSE)
  } else NULL

  display <- vapply(students, student_name_fn, character(1), USE.NAMES = FALSE)
  clash <- duplicated(display) | duplicated(display, fromLast = TRUE)
  if (any(clash)) {
    warning("Folders with the same display name; using folder names instead: ",
            paste(students[clash], collapse = ", "))
    display[clash] <- students[clash]
  }

  # One task per (student, exercise), in output order.
  tasks <- data.frame(
    folder   = rep(students, each = length(exercises)),
    name     = rep(display, each = length(exercises)),
    exercise = rep(exercises, times = length(students)),
    stringsAsFactors = FALSE
  )
  tasks$file <- mapply(find_student_file, file.path(dir, tasks$folder),
                       tasks$exercise, USE.NAMES = FALSE)
  protected <- setdiff(protected_names(), allow_masking)

  results <- vector("list", nrow(tasks))
  running <- list()
  i <- 0L
  while (i < nrow(tasks) || length(running) > 0) {
    # Start tasks until every worker is busy. inproc tasks finish right away.
    while (i < nrow(tasks) && length(running) < workers) {
      i <- i + 1L
      name <- tasks$name[[i]]
      file <- tasks$file[[i]]
      if (i == 1L || tasks$folder[[i]] != tasks$folder[[i - 1L]]) {
        if (use_cli) {
          cli::cli_progress_update(id = progress_id, status = name)
        } else {
          message("Grading: ", name)
        }
      }

      if (is.na(file)) {
        results[[i]] <- new_grade_results(data.frame(
          student  = name,
          exercise = tasks$exercise[[i]],
          test     = NA_character_,
          status   = "missing",
          message  = "no submission",
          duration = NA_real_,
          stringsAsFactors = FALSE
        ))
      } else if (engine == "inproc") {
        results[[i]] <- grade_exercise(file, test_dir = test_dir,
                                       timeout = timeout, student = name,
                                       engine = "inproc",
                                       allow_masking = allow_masking)
      } else {
        job <- start_grading_callr(file, find_test_file(tasks$exercise[[i]], test_dir),
                                   timeout, name, protected)
        if (inherits(job, "grade_results")) {
          results[[i]] <- job
        } else {
          running[[as.character(i)]] <- job
        }
      }
    }

    # Collect callr jobs that ended or ran past their deadline.
    for (key in names(running)) {
      job <- running[[key]]
      if (!job$proc$is_alive() || past_deadline(job)) {
        results[[as.integer(key)]] <- finish_grading_callr(job)
        running[[key]] <- NULL
      }
    }
    if (length(running) > 0) Sys.sleep(0.02)
  }

  if (use_cli) cli::cli_progress_done(id = progress_id)

  combined <- do.call(rbind, lapply(results, unclass_df))
  new_grade_results(combined)
}

# ---------- internal helpers ----------

run_one_test_inproc <- function(fn, timeout) {
  t0 <- Sys.time()
  on.exit(setTimeLimit(elapsed = Inf, transient = FALSE), add = TRUE)
  if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)

  # Count passed testthat expectations; a failed one arrives as an error.
  n_ok <- 0L
  out <- tryCatch(
    list(value = withCallingHandlers(fn(), expectation_success = function(c) {
      n_ok <<- n_ok + 1L
      tryInvokeRestart("continue_test")
    }), err = NULL),
    error = function(e) list(value = NULL, err = e)
  )
  duration <- as.numeric(difftime(Sys.time(), t0, units = "secs"))

  if (inherits(out$err, "expectation_failure")) {
    return(list(status = "fail", message = conditionMessage(out$err),
                duration = duration))
  }
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
  if (n_ok > 0) {
    return(list(status = "pass", message = NA_character_, duration = duration))
  }
  list(
    status   = "fail",
    message  = paste0("test returned non-logical: ", class(out$value)[[1]]),
    duration = duration
  )
}

# UTF-8 if the file is valid UTF-8, else Latin-1 (older Windows editors).
source_encoding <- function(path) {
  bytes <- readBin(path, "raw", file.size(path))
  if (validUTF8(rawToChar(bytes[bytes != as.raw(0)]))) "UTF-8" else "latin1"
}

# Names a student may not redefine: base plus the packages attached by default.
protected_names <- function() {
  pkgs <- c("stats", "utils", "methods", "graphics", "grDevices")
  if (requireNamespace("testthat", quietly = TRUE)) pkgs <- c(pkgs, "testthat")
  unique(c(ls(baseenv(), all.names = TRUE),
           unlist(lapply(pkgs, getNamespaceExports), use.names = FALSE)))
}

# Copies objects from `from` into `to`, skipping protected names. Returns the
# skipped names.
copy_student_objects <- function(from, to, protected) {
  nms <- ls(from, all.names = TRUE)
  masked <- intersect(nms, protected)
  for (nm in setdiff(nms, masked)) assign(nm, get(nm, envir = from), envir = to)
  masked
}

add_masking_note <- function(df, masked) {
  if (length(masked) == 0 || nrow(df) == 0) return(df)
  note <- paste0("ignored student definitions that mask base functions: ",
                 paste(masked, collapse = ", "))
  df$message <- ifelse(is.na(df$message), note, paste0(df$message, "; ", note))
  df
}

find_test_file <- function(exercise, test_dir) {
  target <- tolower(paste0("test_", exercise, ".R"))
  matches <- list.files(test_dir, full.names = TRUE)
  hit <- matches[tolower(basename(matches)) == target]
  if (length(hit) == 0) NULL else hit[[1]]
}

test_exercise <- function(test_file) {
  sub("^test_", "", tools::file_path_sans_ext(basename(test_file)))
}

# The student's file for an exercise, ignoring case: .R first, then .Rmd and
# .qmd. NA if there is none.
find_student_file <- function(dir, exercise) {
  files <- list.files(dir)
  for (ext in c(".R", ".Rmd", ".qmd")) {
    hit <- files[tolower(files) == tolower(paste0(exercise, ext))]
    if (length(hit) > 0) return(file.path(dir, hit[[1]]))
  }
  NA_character_
}

# Path to the R code of a submission: the file itself, or the code chunks of
# an .Rmd or .qmd file, extracted with knitr::purl().
r_code_path <- function(file) {
  if (!tolower(tools::file_ext(file)) %in% c("rmd", "qmd")) return(file)
  if (!requireNamespace("knitr", quietly = TRUE)) {
    stop("Package 'knitr' is required to grade .Rmd and .qmd files. ",
         "Install with: install.packages('knitr')")
  }
  # purl() picks the chunk syntax from the extension; .qmd uses the same one.
  input <- tempfile(fileext = ".Rmd")
  file.copy(file, input)
  knitr::purl(input, output = tempfile(fileext = ".R"), quiet = TRUE,
              documentation = 0)
}

source_error_result <- function(student, exercise, message) {
  new_grade_results(data.frame(
    student  = student,
    exercise = exercise,
    test     = NA_character_,
    status   = "source_error",
    message  = message,
    duration = NA_real_,
    stringsAsFactors = FALSE
  ))
}

expected_exercises <- function(test_dir) {
  files <- list.files(test_dir, pattern = "^test_.+\\.R$", full.names = FALSE)
  stems <- tools::file_path_sans_ext(files)
  sub("^test_", "", stems)
}

# Used by callr engine to know which test functions to invoke without loading
# the student file in the main process.
discover_test_fns <- function(test_file, exercise) {
  env <- new.env(parent = globalenv())
  # Provide a stub for any function called at top-level by the test file that
  # could fail without the student definitions; tests should only define
  # functions, so sourcing here should be safe.
  src <- tryCatch({source(test_file, local = env, encoding = source_encoding(test_file)); TRUE}, error = function(e) FALSE)
  if (!isTRUE(src)) return(character())
  prefix <- paste0("test_", exercise, "_")
  fns <- ls(envir = env)
  fns[startsWith(fns, prefix)]
}

# Sub-folders of `dir`, without hidden folders or macOS zip metadata.
student_dirs <- function(dir) {
  dirs <- list.dirs(dir, full.names = FALSE, recursive = FALSE)
  dirs[!startsWith(dirs, ".") & dirs != "__MACOSX"]
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

#' Default student-name extractor
#'
#' Splits the folder name on underscores, takes the first segment, lower-cases
#' it, then applies [tools::toTitleCase()]. Examples:
#' `"garcia_juan_12345"` becomes `"Garcia"`; `"lopez"` becomes `"Lopez"`.
#'
#' @param folder Character. Submission folder name.
#' @return Character. Display name.
#' @export
#' @examples
#' default_student_name("garcia_juan_12345")
#' default_student_name("LOPEZ")
default_student_name <- function(folder) {
  parts <- strsplit(folder, "_")[[1]]
  tools::toTitleCase(tolower(parts[[1]]))
}

# Kept for internal use; thin alias.
student_name <- function(folder) default_student_name(folder)

unclass_df <- function(x) {
  attr(x, "class") <- "data.frame"
  x
}
