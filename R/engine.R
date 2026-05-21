#' Run an exercise in a subprocess via callr
#'
#' Internal. Returns a list with the per-test outcomes, or a tagged
#' source_error / killed result. Each test gets a real wall-clock kill if
#' the subprocess exceeds the budget.
#'
#' @noRd
run_exercise_callr <- function(student_file, test_file, test_fns, timeout) {
  if (!requireNamespace("callr", quietly = TRUE)) {
    stop("Package 'callr' is required for engine = 'callr'. ",
         "Install with: install.packages('callr')")
  }

  proc <- callr::r_bg(
    func = function(student_file, test_file, test_fns, timeout) {
      env <- new.env(parent = baseenv())
      src <- tryCatch({source(student_file, local = env); TRUE},
                      error = function(e) conditionMessage(e))
      if (!isTRUE(src)) {
        return(list(kind = "source_error", message = src))
      }
      source(test_file, local = env)
      results <- list()
      for (fn in test_fns) {
        t0 <- Sys.time()
        if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
        out <- tryCatch(list(v = get(fn, envir = env)(), err = NULL),
                        error = function(e) list(v = NULL, err = conditionMessage(e)))
        setTimeLimit(elapsed = Inf, transient = FALSE)
        results[[fn]] <- c(out, list(duration = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
      }
      list(kind = "tests", results = results)
    },
    args = list(
      student_file = student_file,
      test_file    = test_file,
      test_fns     = test_fns,
      timeout      = timeout
    )
  )

  n <- max(length(test_fns), 1L)
  wall_ms <- if (is.finite(timeout)) ceiling((timeout * n + 5) * 1000) else -1L
  proc$wait(timeout = wall_ms)
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
