#' Grade an exercise in a subprocess via callr
#'
#' Internal. `start_grading_callr()` launches the subprocess and returns a
#' job, or a finished grade_results when there is nothing to run.
#' `finish_grading_callr()` collects the job, killing it first if it is past
#' its wall-clock deadline. Between the two, callers wait with
#' `wait_ms(job)` or poll `job$proc$is_alive()`.
#'
#' @noRd
start_grading_callr <- function(file, test_file, timeout, student, protected) {
  exercise <- tools::file_path_sans_ext(basename(file))
  test_fns <- discover_test_fns(test_file, exercise)
  if (length(test_fns) == 0) return(empty_grade_results())
  n <- max(length(test_fns), 1L)
  budget <- if (is.finite(timeout)) timeout * n + 5 else Inf
  list(
    proc     = start_exercise_callr(file, test_file, test_fns, timeout, protected),
    deadline = as.numeric(Sys.time()) + budget,
    file = file, test_fns = test_fns, timeout = timeout,
    student = student, exercise = exercise
  )
}

finish_grading_callr <- function(job) {
  out <- finish_exercise_callr(job$proc)
  if (identical(out$kind, "source_error")) {
    warning("Failed to source ", basename(job$file), ": ", out$message)
  }
  df <- callr_to_rows(out, job$test_fns, job$timeout, job$student, job$exercise)
  new_grade_results(add_masking_note(df, out$masked))
}

# Milliseconds left before the job's deadline, as proc$wait() expects.
wait_ms <- function(job) {
  if (!is.finite(job$deadline)) return(-1L)
  max(0, ceiling((job$deadline - as.numeric(Sys.time())) * 1000))
}

past_deadline <- function(job) as.numeric(Sys.time()) > job$deadline

start_exercise_callr <- function(student_file, test_file, test_fns, timeout,
                                 protected = character()) {
  callr::r_bg(
    func = function(student_file, test_file, test_fns, timeout, protected,
                    encodings) {
      # Files the student writes land in the subprocess's own temp dir.
      setwd(tempdir())
      student_env <- new.env(parent = baseenv())
      src <- tryCatch({source(student_file, local = student_env, encoding = encodings[[1]]); TRUE},
                      error = function(e) conditionMessage(e))
      if (!isTRUE(src)) {
        return(list(kind = "source_error", message = src))
      }
      # Same isolation as the inproc engine (see copy_student_objects()).
      env <- new.env(parent = baseenv())
      nms <- ls(student_env, all.names = TRUE)
      masked <- intersect(nms, protected)
      for (nm in setdiff(nms, masked)) assign(nm, get(nm, envir = student_env), envir = env)
      source(test_file, local = env, encoding = encodings[[2]])
      results <- list()
      for (fn in test_fns) {
        t0 <- Sys.time()
        if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
        out <- tryCatch(list(v = get(fn, envir = env)(), err = NULL),
                        error = function(e) list(v = NULL, err = conditionMessage(e)))
        setTimeLimit(elapsed = Inf, transient = FALSE)
        results[[fn]] <- c(out, list(duration = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      }
      list(kind = "tests", results = results, masked = masked)
    },
    args = list(
      student_file = normalizePath(student_file),
      test_file    = normalizePath(test_file),
      test_fns     = test_fns,
      timeout      = timeout,
      protected    = protected,
      encodings    = c(source_encoding(student_file), source_encoding(test_file))
    )
  )
}

finish_exercise_callr <- function(proc) {
  if (proc$is_alive()) {
    proc$kill()
    return(list(kind = "killed"))
  }
  tryCatch(proc$get_result(), error = function(e) {
    list(kind = "process_error", message = conditionMessage(e))
  })
}

callr_to_rows <- function(out, test_fns, timeout, student, exercise) {
  if (identical(out$kind, "source_error")) {
    return(data.frame(
      student  = student,
      exercise = exercise,
      test     = NA_character_,
      status   = "source_error",
      message  = out$message,
      duration = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  if (identical(out$kind, "killed")) {
    return(data.frame(
      student  = student,
      exercise = exercise,
      test     = test_fns,
      status   = "timeout",
      message  = sprintf("exceeded wall-clock budget (~%g s per test)", timeout),
      duration = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  if (identical(out$kind, "process_error")) {
    return(data.frame(
      student  = student,
      exercise = exercise,
      test     = NA_character_,
      status   = "error",
      message  = out$message,
      duration = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  # tests
  rows <- lapply(test_fns, function(fn) {
    r <- out$results[[fn]]
    if (is.null(r)) {
      return(data.frame(
        student = student, exercise = exercise, test = fn,
        status = "error", message = "no result returned",
        duration = NA_real_, stringsAsFactors = FALSE
      ))
    }
    if (!is.null(r$err)) {
      is_timeout <- grepl("elapsed time limit|CPU time limit", r$err)
      return(data.frame(
        student = student, exercise = exercise, test = fn,
        status = if (is_timeout) "timeout" else "error",
        message = r$err, duration = r$duration, stringsAsFactors = FALSE
      ))
    }
    if (isTRUE(r$v)) {
      return(data.frame(student = student, exercise = exercise, test = fn,
                        status = "pass", message = NA_character_,
                        duration = r$duration, stringsAsFactors = FALSE))
    }
    if (isFALSE(r$v)) {
      return(data.frame(student = student, exercise = exercise, test = fn,
                        status = "fail", message = NA_character_,
                        duration = r$duration, stringsAsFactors = FALSE))
    }
    data.frame(student = student, exercise = exercise, test = fn,
               status = "fail",
               message = paste0("test returned non-logical: ", class(r$v)[[1]]),
               duration = r$duration, stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
