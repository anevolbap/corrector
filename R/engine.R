#' Grade an exercise in a subprocess via callr
#'
#' Internal. `start_grading_callr()` launches the subprocess and returns a
#' job, or a finished grade_results when there is nothing to run.
#' `finish_grading_callr()` collects the job, killing it first if it is past
#' its wall-clock deadline. Between the two, callers wait with
#' `wait_ms(job)` or poll `job$proc$is_alive()`.
#'
#' @noRd
start_grading_callr <- function(file, test_file, timeout, student, protected,
                                allow_masking = character(), isolated = FALSE) {
  exercise <- test_exercise(test_file)
  test_fns <- discover_test_fns(test_file, exercise)
  if (length(test_fns) == 0) return(empty_grade_results())
  code <- tryCatch(r_code_path(file), error = function(e) e)
  if (inherits(code, "error")) {
    warning("Failed to source ", basename(file), ": ", conditionMessage(code))
    return(source_error_result(student, exercise, conditionMessage(code)))
  }
  n <- max(length(test_fns), 1L)
  budget <- if (is.finite(timeout)) timeout * n + 5 else Inf
  progress <- tempfile("corrector_progress", fileext = ".rds")
  list(
    proc     = start_exercise_callr(code, test_file, test_fns, timeout, protected,
                                    progress, allow_masking, isolated),
    deadline = as.numeric(Sys.time()) + budget,
    progress = progress,
    isolated = isolated,
    suspicious = scan_code(code),
    file = file, test_fns = test_fns, timeout = timeout,
    student = student, exercise = exercise
  )
}

finish_grading_callr <- function(job) {
  out <- finish_exercise_callr(job$proc)
  # A killed subprocess saved the tests it finished; keep those results.
  # Not for the isolated engine: student code there runs in another process
  # that could reach the file, while the test process itself is rarely killed.
  saved <- if (identical(out$kind, "killed") && !isTRUE(job$isolated) &&
               file.exists(job$progress)) {
    tryCatch(readRDS(job$progress), error = function(e) NULL)
  }
  if (!is.null(saved)) {
    out <- list(kind = "tests", results = saved$results, masked = saved$masked,
                killed = TRUE)
  }
  unlink(c(job$progress, paste0(job$progress, ".tmp")))
  if (identical(out$kind, "source_error")) {
    warning("Failed to source ", basename(job$file), ": ", out$message)
  }
  df <- callr_to_rows(out, job$test_fns, job$timeout, job$student, job$exercise)
  df <- add_masking_note(df, out$masked)
  if (identical(out$kind, "tests")) {
    df <- add_note(df, "suspicious code: ", job$suspicious)
    df <- add_note(df, "tampering: ", out$tampered)
  }
  new_grade_results(df)
}

# Milliseconds left before the job's deadline, as proc$wait() expects.
wait_ms <- function(job) {
  if (!is.finite(job$deadline)) return(-1L)
  max(0, ceiling((job$deadline - as.numeric(Sys.time())) * 1000))
}

past_deadline <- function(job) as.numeric(Sys.time()) > job$deadline

start_exercise_callr <- function(student_file, test_file, test_fns, timeout,
                                 protected = character(), progress_file = tempfile(),
                                 allow_masking = character(), isolated = FALSE) {
  args <- list(
    student_file = normalizePath(student_file),
    test_file    = normalizePath(test_file),
    test_fns     = test_fns,
    timeout      = timeout,
    protected    = protected,
    encodings    = c(source_encoding(student_file), source_encoding(test_file)),
    progress_file = progress_file,
    allow        = allow_masking,
    method_pattern = comparison_methods,
    snapshot     = portable(integrity_snapshot),
    changes      = portable(integrity_changes),
    run_loop     = portable(run_test_loop)
  )
  if (isolated) {
    return(callr::r_bg(
      func = run_in_child,
      args = c(list(portable(isolated_child)), args,
               list(load = portable(isolated_load), unsafe = portable(unsafe_value))),
      stdout = NULL,
      stderr = NULL
    ))
  }
  callr::r_bg(
    func = run_in_child,
    args = c(list(portable(callr_child)), args),
    # Discard student output: an unread pipe fills up and stalls the child.
    stdout = NULL,
    stderr = NULL
  )
}

# The child process for engine = "callr". Like isolated_child(), it is
# sent with portable() and run through run_in_child().
callr_child <- function(student_file, test_file, test_fns, timeout, protected,
                encodings, progress_file, allow, method_pattern,
                snapshot, changes, run_loop) {
  # Files the student writes land in the subprocess's own temp dir.
  setwd(tempdir())
  student_env <- new.env(parent = globalenv())
  # Same stubs as add_quit_stubs().
  stub <- function(...) stop("quit() is not allowed while grading", call. = FALSE)
  attr(stub, "corrector_stub") <- TRUE
  assign("quit", stub, envir = student_env)
  assign("q", stub, envir = student_env)
  snap <- snapshot()
  if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
  src <- tryCatch({source(student_file, local = student_env, encoding = encodings[[1]]); TRUE},
                  error = function(e) conditionMessage(e))
  setTimeLimit(elapsed = Inf, transient = FALSE)
  if (!isTRUE(src) && grepl("elapsed time limit|CPU time limit", src)) {
    return(list(kind = "load_timeout"))
  }
  if (!isTRUE(src)) {
    return(list(kind = "source_error", message = src))
  }
  # Same isolation as the inproc engine (see copy_student_objects()).
  env <- new.env(parent = globalenv())
  nms <- ls(student_env, all.names = TRUE)
  masked <- union(intersect(nms, protected),
                  setdiff(grep(method_pattern, nms, value = TRUE), allow))
  for (nm in setdiff(nms, masked)) assign(nm, get(nm, envir = student_env), envir = env)
  masked <- masked[!vapply(masked, function(nm) {
    isTRUE(attr(get(nm, envir = student_env), "corrector_stub"))
  }, logical(1))]
  source(test_file, local = env, encoding = encodings[[2]])
  parent.env(env) <- parent.env(globalenv())
  tampered <- changes(snap)
  snap_tests <- snapshot()
  results <- run_loop(env, test_fns, timeout, progress_file, masked)
  list(kind = "tests", results = results, masked = masked,
       tampered = unique(c(tampered, changes(snap_tests))))
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
  if (identical(out$kind, "load_timeout")) {
    return(as.data.frame(load_timeout_result(student, exercise, test_fns, timeout)))
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
    if (is.null(r) && isTRUE(out$killed)) {
      return(data.frame(
        student = student, exercise = exercise, test = fn,
        status = "timeout",
        message = sprintf("exceeded wall-clock budget (~%g s per test)", timeout),
        duration = NA_real_, stringsAsFactors = FALSE
      ))
    }
    if (is.null(r)) {
      return(data.frame(
        student = student, exercise = exercise, test = fn,
        status = "error", message = "no result returned",
        duration = NA_real_, stringsAsFactors = FALSE
      ))
    }
    if (!is.null(r$err)) {
      is_timeout <- grepl("elapsed time limit|CPU time limit", r$err)
      status <- if (isTRUE(r$failed)) "fail" else if (is_timeout) "timeout" else "error"
      return(data.frame(
        student = student, exercise = exercise, test = fn,
        status = status,
        message = r$err, duration = r$duration, stringsAsFactors = FALSE
      ))
    }
    if (isTRUE(r$v) || isTRUE(r$n_ok > 0 && !isFALSE(r$v))) {
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
