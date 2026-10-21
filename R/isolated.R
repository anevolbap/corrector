# The isolated engine. Tests run in one R process (B, the callr child) and
# student code in another (A, a callr::r_session that B starts). In B each
# student function is a stand-in that runs the real one in A and returns the
# result as plain data, so nothing a student does in A (attach(), S3
# methods, changed base functions) can change how B compares values.
#
# Every function in this file runs in a subprocess, so it uses only base R
# and callr, and reaches other helpers through its arguments. portable()
# rebases them to the base environment before they are sent.

# Runs each test in `env` and returns the per-test outcomes. Shared by the
# callr and isolated engines; run_one_test_inproc() is the inproc version.
run_test_loop <- function(env, test_fns, timeout, progress_file, masked) {
  results <- list()
  for (fn in test_fns) {
    t0 <- Sys.time()
    if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
    n_ok <- 0L
    out <- tryCatch(
      list(v = withCallingHandlers(get(fn, envir = env)(),
                                   expectation_success = function(c) {
                                     n_ok <<- n_ok + 1L
                                     tryInvokeRestart("continue_test")
                                   }),
           err = NULL, failed = FALSE),
      error = function(e) list(v = NULL, err = conditionMessage(e),
                               failed = inherits(e, "expectation_failure")),
      skip = function(e) list(v = NULL, failed = FALSE,
                              err = paste("test skipped:",
                                          sub("^Reason: ", "", conditionMessage(e)))))
    setTimeLimit(elapsed = Inf, transient = FALSE)
    results[[fn]] <- c(out, list(n_ok = n_ok,
                                 duration = as.numeric(difftime(Sys.time(), t0, units = "secs"))))
    # Write then rename, so a kill never leaves a half-written file.
    saveRDS(list(results = results, masked = masked), paste0(progress_file, ".tmp"))
    file.rename(paste0(progress_file, ".tmp"), progress_file)
  }
  results
}

# Runs in session A: loads the student file and keeps its environment in
# A's global environment for later calls.
isolated_load <- function(student_file, encoding, timeout, snapshot, changes) {
  setwd(tempdir())
  student_env <- new.env(parent = globalenv())
  stub <- function(...) stop("quit() is not allowed while grading", call. = FALSE)
  attr(stub, "corrector_stub") <- TRUE
  assign("quit", stub, envir = student_env)
  assign("q", stub, envir = student_env)
  snap <- snapshot()
  if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
  src <- tryCatch({source(student_file, local = student_env, encoding = encoding); TRUE},
                  error = function(e) conditionMessage(e))
  setTimeLimit(elapsed = Inf, transient = FALSE)
  if (!isTRUE(src) && grepl("elapsed time limit|CPU time limit", src)) {
    return(list(kind = "load_timeout"))
  }
  if (!isTRUE(src)) return(list(kind = "source_error", message = src))
  assign(".corrector_student", student_env, envir = globalenv())
  assign(".corrector_snap", snap, envir = globalenv())
  nms <- ls(student_env, all.names = TRUE)
  is_fn <- vapply(nms, function(nm) is.function(get(nm, envir = student_env)), logical(1))
  is_stub <- vapply(nms, function(nm) {
    isTRUE(attr(get(nm, envir = student_env), "corrector_stub"))
  }, logical(1))
  list(kind = "ok", functions = nms[is_fn & !is_stub],
       data = mget(nms[!is_fn], envir = student_env),
       tampered = changes(snap))
}

# Why `x` cannot be sent back to B, or NULL if it is plain data. Functions,
# environments and code objects could carry student code into B.
unsafe_value <- function(x) {
  if (is.function(x)) return("a function")
  if (is.environment(x)) return("an environment")
  if (is.language(x) || is.symbol(x)) return("an R expression")
  if (typeof(x) %in% c("externalptr", "weakref", "bytecode", "promise", "S4")) {
    return(paste("an object of type", typeof(x)))
  }
  for (a in attributes(x)) {
    why <- Recall(a)
    if (!is.null(why)) return(why)
  }
  if (is.list(x)) {
    for (el in x) {
      why <- Recall(el)
      if (!is.null(why)) return(why)
    }
  }
  NULL
}

# The child process B for engine = "isolated".
isolated_child <- function(student_file, test_file, test_fns, timeout, protected,
                           encodings, progress_file, allow, method_pattern,
                           snapshot, changes, run_loop, load, unsafe) {
  setwd(tempdir())
  state <- new.env()
  start_a <- function() {
    a <- callr::r_session$new(
      # supervise: A dies with B when B is killed.
      options = callr::r_session_options(stdout = NULL, stderr = NULL, supervise = TRUE),
      wait = TRUE
    )
    loaded <- a$run(function(.f, ...) .f(...),
                    list(load, student_file, encodings[[1]], timeout, snapshot, changes))
    state$a <- a
    loaded
  }
  loaded <- start_a()
  if (!identical(loaded$kind, "ok")) {
    state$a$kill()
    return(loaded)
  }

  # Code sent to A must not see A's search path (see run_in_child()).
  in_a <- function(.f, ...) .f(...)
  runner <- function(name, args) {
    do.call(get(name, envir = get(".corrector_student", envir = globalenv())), args)
  }
  environment(runner) <- baseenv()
  later_changes <- function(changes) changes(get(".corrector_snap", envir = globalenv()))
  environment(later_changes) <- baseenv()

  # Runs student function `name` in A. Waits in short slices so the test's
  # time limit still applies; if the call does not finish, A is killed and
  # started again for the next test.
  call_student <- function(name, args) {
    if (is.null(state$a) || !state$a$is_alive()) start_a()
    a <- state$a
    a$call(in_a, list(runner, name, args))
    finished <- FALSE
    on.exit(if (!finished) {
      a$kill()
      state$a <- NULL
    })
    while (a$poll_process(100) != "ready") NULL
    r <- a$read()
    finished <- TRUE
    if (!is.null(r$error)) {
      err <- if (!is.null(r$error$parent)) r$error$parent else r$error
      stop(conditionMessage(err), call. = FALSE)
    }
    why <- unsafe(r$result)
    if (!is.null(why)) {
      stop(name, "() returned ", why, "; the isolated engine only accepts data",
           call. = FALSE)
    }
    r$result
  }
  make_stand_in <- function(name) {
    force(name)
    function(...) call_student(name, list(...))
  }

  nms <- c(loaded$functions, names(loaded$data))
  masked <- union(intersect(nms, protected),
                  setdiff(grep(method_pattern, nms, value = TRUE), allow))
  env <- new.env(parent = globalenv())
  for (nm in setdiff(loaded$functions, masked)) assign(nm, make_stand_in(nm), envir = env)
  for (nm in setdiff(names(loaded$data), masked)) {
    if (is.null(unsafe(loaded$data[[nm]]))) assign(nm, loaded$data[[nm]], envir = env)
  }
  source(test_file, local = env, encoding = encodings[[2]])
  parent.env(env) <- parent.env(globalenv())

  results <- run_loop(env, test_fns, timeout, progress_file, masked)

  tampered <- loaded$tampered
  if (!is.null(state$a) && state$a$is_alive()) {
    later <- tryCatch(
      state$a$run(in_a, list(later_changes, changes)),
      error = function(e) character()
    )
    tampered <- unique(c(tampered, later))
    state$a$kill()
  }
  list(kind = "tests", results = results, masked = masked, tampered = tampered)
}
