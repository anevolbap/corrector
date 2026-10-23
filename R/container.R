# engine = "container": the isolated pair (tests in process B, student code
# in session A) runs inside a container with no network, limited memory and
# processes, a read-only system, and only this exercise's files mounted.
# Student code then cannot reach the teacher's files or network.

container_cmd <- function() getOption("corrector.container_cmd", "docker")
container_image <- function() getOption("corrector.container_image", "corrector-runner")

# Stops with build instructions when the container tool or image is missing.
check_container <- function() {
  cmd <- container_cmd()
  if (!nzchar(Sys.which(cmd))) {
    stop("engine = \"container\" needs ", cmd, " (set ",
         "options(corrector.container_cmd = ) for another tool)", call. = FALSE)
  }
  status <- suppressWarnings(system2(cmd, c("image", "inspect", container_image()),
                                     stdout = FALSE, stderr = FALSE))
  if (!identical(status, 0L)) {
    stop("Container image '", container_image(), "' not found. Build it with:\n  ",
         cmd, " build -t ", container_image(), " ",
         shQuote(system.file("container", package = "corrector")), call. = FALSE)
  }
  invisible(TRUE)
}

# Starts one exercise in a container. Returns the process, wrapped so that
# finish_exercise_callr() can use it like a callr process, and the host path
# of the progress file.
start_exercise_container <- function(student_file, test_file, test_fns, timeout,
                                     protected, allow_masking) {
  job <- tempfile("corrector_job")
  dir.create(file.path(job, "in"), recursive = TRUE)
  dir.create(file.path(job, "out"))
  file.copy(student_file, file.path(job, "in", "student.R"))
  file.copy(test_file, file.path(job, "in", "test.R"))
  saveRDS(list(
    f = portable(isolated_child),
    args = list(
      student_file = "/job/in/student.R",
      test_file = "/job/in/test.R",
      test_fns = test_fns,
      timeout = timeout,
      protected = protected,
      encodings = c(source_encoding(student_file), source_encoding(test_file)),
      progress_file = "/job/out/progress.rds",
      allow = allow_masking,
      method_pattern = comparison_methods,
      snapshot = portable(integrity_snapshot),
      changes = portable(integrity_changes),
      run_loop = portable(run_test_loop),
      load = portable(isolated_load),
      unsafe = portable(unsafe_value)
    )
  ), file.path(job, "in", "job.rds"))

  name <- basename(job)
  script <- paste(
    "j <- readRDS('/job/in/job.rds');",
    "r <- tryCatch(list(ok = TRUE, value = do.call(j$f, j$args)),",
    "error = function(e) list(ok = FALSE, message = conditionMessage(e)));",
    "saveRDS(r, '/job/out/result.rds')"
  )
  user <- if (.Platform$OS.type == "unix" && Sys.info()[["sysname"]] == "Linux") {
    c("--user", paste0(system2("id", "-u", stdout = TRUE), ":",
                       system2("id", "-g", stdout = TRUE)))
  }
  args <- c(
    "run", "--rm", "--name", name,
    "--network", "none", "--memory", "2g", "--pids-limit", "512",
    "--read-only", "--tmpfs", "/tmp:rw,exec", "-e", "HOME=/tmp", user,
    "-v", paste0(normalizePath(file.path(job, "in")), ":/job/in:ro"),
    "-v", paste0(normalizePath(file.path(job, "out")), ":/job/out"),
    "-w", "/tmp", container_image(), "Rscript", "-e", script
  )
  stderr_file <- file.path(job, "stderr.txt")
  p <- processx::process$new(container_cmd(), args, stdout = NULL, stderr = stderr_file)

  proc <- list(
    is_alive = function() p$is_alive(),
    wait = function(timeout = -1) p$wait(timeout),
    # Removing the container stops it even if the client process is gone.
    kill = function() {
      system2(container_cmd(), c("rm", "-f", name), stdout = FALSE, stderr = FALSE)
      p$kill()
    },
    get_result = function() {
      on.exit(unlink(job, recursive = TRUE), add = TRUE)
      result <- file.path(job, "out", "result.rds")
      if (!file.exists(result)) {
        err <- if (file.exists(stderr_file)) readLines(stderr_file, warn = FALSE) else ""
        stop("the container did not return a result: ",
             paste(utils::tail(err, 3), collapse = " "), call. = FALSE)
      }
      r <- readRDS(result)
      if (!isTRUE(r$ok)) stop(r$message, call. = FALSE)
      r$value
    }
  )
  list(proc = proc, progress = file.path(job, "out", "progress.rds"))
}
