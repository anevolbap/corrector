#' Corregir un ejercicio contra sus tests
#'
#' Carga el archivo del estudiante y el archivo de tests que le corresponde
#' en un entorno aislado, corre cada función cuyo nombre empieza con
#' `test_<exercise>_` y devuelve el resultado de cada test como un objeto
#' [grade_results].
#'
#' Un test pasa si devuelve `TRUE`. Los tests también pueden usar
#' expectativas de \pkg{testthat} (llamá a `library(testthat)` al principio
#' del archivo de tests): el test pasa cuando al menos una expectativa se
#' cumple y ninguna falla. Una expectativa que falla queda registrada como
#' `fail` con su mensaje.
#'
#' @section English:
#' **Grade a single exercise file against its tests.** Sources the student's
#' file and the matching test file into an isolated environment, runs every
#' function whose name starts with `test_<exercise>_`, and returns the
#' per-test outcome as a [grade_results] object.
#'
#' A test passes if it returns `TRUE`. Tests can also use \pkg{testthat}
#' expectations (call `library(testthat)` at the top of the test file): the
#' test passes when at least one expectation succeeds and none fails, and a
#' failed expectation is recorded as `fail` with its message.
#'
#' @param file Ruta al archivo del estudiante: un script de R (por ejemplo
#'   `"ejercicio1.R"`) o un documento R Markdown o Quarto (`.Rmd`, `.qmd`),
#'   del que se extraen los bloques de código R con `knitr::purl()`. El
#'   archivo de tests que le corresponde se busca sin distinguir mayúsculas
#'   de minúsculas.
#'   *English:* Path to the student's file: an R script (e.g. `"ejercicio1.R"`)
#'   or an R Markdown or Quarto document (`.Rmd`, `.qmd`), whose R chunks are
#'   extracted with `knitr::purl()`. The matching test file is found ignoring
#'   case.
#' @param test_dir Carpeta que contiene los archivos de tests.
#'   *English:* Directory that contains the test files.
#' @param timeout Máximo de segundos permitido para cada función de test y
#'   para cargar el archivo del estudiante. Los tests que lo superan quedan
#'   registrados con estado `timeout`. Por defecto 10. Usá `Inf` para no
#'   poner límite.
#'   *English:* Maximum seconds allowed per test function, and for loading
#'   the student's file. Tests that exceed it are recorded with status
#'   `timeout`. Default 10. Use `Inf` for no limit.
#' @param student Nombre opcional del estudiante para mostrar. Por defecto
#'   `NA`.
#'   *English:* Optional student display name. Defaults to `NA`.
#' @param engine `"callr"` (por defecto) corre cada ejercicio en un subproceso
#'   nuevo de R con el paquete \pkg{callr}, con una carpeta de trabajo
#'   temporal. El timeout es un límite estricto de tiempo real, y las
#'   asignaciones con `<<-` o los archivos que escribe el estudiante no llegan
#'   a tu sesión ni a tu carpeta.
#'   `"inproc"` corre los tests en la sesión de R actual. Es más rápido, pero
#'   su timeout con `setTimeLimit()` no corta todo tipo de bucle, y el código
#'   del estudiante puede ver y cambiar tu entorno global.
#'   `"isolated"` corre los tests en un subproceso y el código del estudiante
#'   en otro. Cada función del estudiante que llaman los tests corre en el
#'   proceso del estudiante y solo vuelve su resultado (datos simples). Así,
#'   trucos como `attach()`, métodos S3 para comparaciones o funciones base
#'   reemplazadas no cambian la nota. Es más lento, y una función del
#'   estudiante no puede devolver una función ni un entorno. Usalo cuando
#'   te importa evitar trampas.
#'   `"container"` hace lo mismo que `"isolated"`, pero dentro de un
#'   contenedor de Docker sin red, con memoria limitada y solo con los
#'   archivos del ejercicio, así el código del estudiante no llega a tus
#'   archivos ni a tu red. Necesita Docker (o
#'   `options(corrector.container_cmd = "podman")`) y la imagen
#'   `corrector-runner` (otra con `options(corrector.container_image = )`);
#'   el archivo para construirla está en
#'   `system.file("container", package = "corrector")`.
#'   *English:* `"callr"` (default) runs each exercise in a fresh R
#'   subprocess via the \pkg{callr} package, with a temporary working
#'   directory. The timeout is a hard wall-clock limit, and assignments with
#'   `<<-` or files the student writes do not reach your session or folder.
#'   `"inproc"` runs tests in the current R session. It is faster, but its
#'   `setTimeLimit()` timeout does not interrupt every kind of loop, and
#'   student code can see and change your global environment.
#'   `"isolated"` runs the tests in one subprocess and the student code in
#'   another. Each student function the tests call runs in the student
#'   process and only its result (plain data) comes back, so tricks such as
#'   `attach()`, S3 methods for comparisons or replaced base functions do
#'   not change the grade. It is slower, and a student function may not
#'   return a function or an environment. Use it when cheating matters.
#'   `"container"` does the same as `"isolated"`, but inside a Docker
#'   container with no network, limited memory and only the exercise's
#'   files, so student code cannot reach your files or network. It needs
#'   Docker (or `options(corrector.container_cmd = "podman")`) and the image
#'   `corrector-runner` (another one with
#'   `options(corrector.container_image = )`); the file to build it is in
#'   `system.file("container", package = "corrector")`.
#' @param allow_masking Vector de texto con nombres de funciones de R base y
#'   de los paquetes por defecto (stats, utils, methods, graphics, grDevices)
#'   que el estudiante puede redefinir, por ejemplo `"factorial"` cuando el
#'   ejercicio lo pide. Cualquier otro objeto del estudiante con uno de esos
#'   nombres no es visible para los tests, así que un estudiante no puede
#'   pasar los tests redefiniendo `all()` o `==`. Los nombres ignorados
#'   aparecen en la columna `message`.
#'   *English:* Character vector of function names from base R and
#'   the default packages (stats, utils, methods, graphics, grDevices) that
#'   the student may redefine, e.g. `"factorial"` when the exercise asks for
#'   it. Any other student object with such a name is not visible to the
#'   tests, so a student cannot pass by redefining `all()` or `==`. Ignored
#'   names are listed in the `message` column.
#' @return Un objeto [grade_results] con una fila por test. Si el archivo del
#'   estudiante tiene errores de sintaxis, una fila con
#'   `status = source_error`. Si no hay un archivo de tests que le
#'   corresponda, una fila con `status = missing` y una advertencia.
#'   *English:* A [grade_results] object with one row per test. If the student
#'   file fails to parse, one row with `status = source_error`. If no matching
#'   test file is found, one row with `status = missing` and a warning.
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
                           engine = c("callr", "inproc", "isolated", "container"),
                           allow_masking = character()) {
  engine <- match.arg(engine)
  if (engine == "container") check_container()
  if (!file.exists(file)) stop("Student file does not exist: ", file, call. = FALSE)
  check_test_dir(test_dir)
  check_timeout(timeout)
  # Absolute paths, so a student's setwd() cannot break the lookup.
  file <- normalizePath(file)
  test_dir <- normalizePath(test_dir)
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

  if (engine != "inproc") {
    job <- start_grading_callr(file, test_file, timeout, student, protected,
                               allow_masking, mode = engine)
    if (inherits(job, "grade_results")) return(job)
    job$proc$wait(timeout = wait_ms(job))
    return(finish_grading_callr(job))
  }

  test_fns <- discover_test_fns(test_file, exercise)

  # Undo what student code may change in this session.
  old_wd <- getwd()
  old_options <- options()
  on.exit({
    setwd(old_wd)
    options(old_options)
  }, add = TRUE)
  # Undo attach(), registered methods and replaced base functions, so they
  # cannot reach the next student.
  snap <- integrity_snapshot()
  on.exit(integrity_restore(snap), add = TRUE)

  student_env <- new.env(parent = globalenv())
  add_quit_stubs(student_env)
  src <- tryCatch({
    code <- r_code_path(file)
    if (is.finite(timeout)) setTimeLimit(elapsed = timeout, transient = FALSE)
    source(code, local = student_env, encoding = source_encoding(code))
    setTimeLimit(elapsed = Inf, transient = FALSE)
    list(ok = TRUE)
  }, error = function(e) {
    setTimeLimit(elapsed = Inf, transient = FALSE)
    list(ok = FALSE, message = conditionMessage(e))
  })

  if (!isTRUE(src$ok) && is_time_limit(src$message)) {
    return(load_timeout_result(student, exercise, test_fns, timeout))
  }
  if (!isTRUE(src$ok)) {
    warning("Failed to source ", basename(file), ": ", src$message)
    return(source_error_result(student, exercise, src$message))
  }

  # Tests run in their own environment. Student objects are copied in, except
  # those that would mask a protected function the tests rely on.
  suspicious <- scan_code(code)
  tampered <- integrity_changes(snap)
  env <- new.env(parent = globalenv())
  masked <- copy_student_objects(student_env, env, protected, allow_masking)
  source(test_file, local = env, encoding = source_encoding(test_file))
  # Tests look up names in the attached packages, not the global env, which
  # student code can write to. Set after sourcing so library() calls count.
  parent.env(env) <- parent.env(globalenv())
  snap_tests <- integrity_snapshot()

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
  tampered <- unique(c(tampered, integrity_changes(snap_tests)))
  df <- add_masking_note(do.call(rbind, rows), masked)
  df <- add_note(df, "suspicious code: ", suspicious)
  new_grade_results(add_note(df, "tampering: ", tampered))
}

#' Corregir todas las entregas de una carpeta o archivo .zip
#'
#' Espera una subcarpeta por estudiante dentro de `submissions_path`. Cada
#' estudiante se corrige en cada ejercicio que tiene un archivo de tests en
#' `test_dir`. Un estudiante que no entrega un ejercicio recibe una fila
#' `missing`. El archivo del estudiante se busca sin distinguir mayúsculas de
#' minúsculas (`Ejercicio1.R` cuenta como `ejercicio1`), y se aceptan
#' archivos `.Rmd` o `.qmd` cuando no hay un archivo `.R`.
#'
#' Si `submissions_path` termina en `.zip`, primero se extrae en una
#' subcarpeta de `tempdir()`. Se ignoran los archivos sueltos, las carpetas
#' ocultas y `__MACOSX`. Si la ruta tiene una sola carpeta sin archivos `.R`,
#' `.Rmd` ni `.qmd` pero con subcarpetas, esas subcarpetas se toman como los
#' estudiantes.
#'
#' @section English:
#' **Grade all student submissions in a directory or zip archive.** Expects
#' one sub-folder per student inside `submissions_path`. Every student is
#' graded on every exercise that has a test file in `test_dir`; a student who
#' omits an exercise gets a `missing` row. The student's file is matched
#' ignoring case (`Ejercicio1.R` counts as `ejercicio1`), and `.Rmd` or `.qmd`
#' files are accepted when there is no `.R` file.
#'
#' If `submissions_path` ends in `.zip` it is extracted into a `tempdir()`
#' subfolder first. Loose files, hidden folders and `__MACOSX` are ignored.
#' If the path holds a single folder with no `.R`, `.Rmd` or `.qmd` files but
#' with sub-folders, those sub-folders are taken as the students.
#'
#' @param submissions_path Ruta a una carpeta o archivo `.zip` con las
#'   entregas.
#'   *English:* Path to a directory or `.zip` archive of submissions.
#' @param test_dir Carpeta que contiene los archivos de tests.
#'   *English:* Directory that contains the test files.
#' @param timeout Máximo de segundos permitido para cada función de test. Por
#'   defecto 10.
#'   *English:* Maximum seconds allowed per test function. Default 10.
#' @param engine `"callr"` (por defecto), `"inproc"`, `"isolated"` o `"container"`.
#'   Mirá [grade_exercise()].
#'   *English:* `"callr"` (default), `"inproc"`, `"isolated"` or `"container"`.
#'   See [grade_exercise()].
#' @param student_name_fn Función que se aplica al nombre de cada carpeta de
#'   estudiante para obtener el nombre para mostrar. Por defecto toma la
#'   primera parte separada por guiones bajos y la pasa a formato título.
#'   Las carpetas que dan el mismo nombre conservan el nombre de la carpeta,
#'   con una advertencia.
#'   *English:* Function applied to each student folder name to
#'   produce the display name. Defaults to taking the first
#'   underscore-separated token and applying title case. Folders that map to the same
#'   name keep their folder name, with a warning.
#' @param allow_masking Nombres de funciones base que los estudiantes pueden
#'   redefinir. Mirá [grade_exercise()].
#'   *English:* Base function names students may redefine. See
#'   [grade_exercise()].
#' @param layout `"folders"` (por defecto): una carpeta por estudiante.
#'   `"moodle"`: el archivo .zip o la carpeta de "Descargar todas las
#'   entregas" de Moodle, con o sin "Descargar entregas en carpetas". Solo se
#'   corrigen las entregas de archivos, y `student_name_fn` pasa a ser por
#'   defecto [moodle_student_name()].
#'   *English:* `"folders"` (default): one folder per student. `"moodle"`:
#'   the zip or folder from Moodle's "Download all submissions", with or
#'   without "Download submissions in folders". Only file submissions are
#'   graded, and `student_name_fn` defaults to [moodle_student_name()].
#' @param workers Cantidad de subprocesos de callr que corren al mismo
#'   tiempo. Por defecto 1. Valores mayores que 1 aceleran la corrección de
#'   cursos grandes; un valor cercano a `parallel::detectCores()` es un buen
#'   límite superior. El motor `"inproc"` lo ignora.
#'   *English:* Number of callr subprocesses to run at the same time.
#'   Default 1. Values above 1 speed up large classes; a value near
#'   `parallel::detectCores()` is a good upper bound. Ignored by the
#'   `"inproc"` engine.
#' @return Un objeto [grade_results].
#'   *English:* A [grade_results] object.
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
                              engine = c("callr", "inproc", "isolated", "container"),
                              student_name_fn = default_student_name,
                              allow_masking = character(),
                              workers = 1L,
                              layout = c("folders", "moodle")) {
  engine <- match.arg(engine)
  if (engine == "container") check_container()
  layout <- match.arg(layout)
  if (!file.exists(submissions_path)) {
    stop("submissions_path does not exist: ", submissions_path, call. = FALSE)
  }
  check_test_dir(test_dir)
  check_timeout(timeout)
  test_dir <- normalizePath(test_dir)
  if (!is.numeric(workers) || length(workers) != 1 || is.na(workers) ||
      workers < 1 || workers != round(workers)) {
    stop("workers must be a whole number of 1 or more", call. = FALSE)
  }
  if (layout == "moodle" && missing(student_name_fn)) {
    student_name_fn <- moodle_student_name
  }
  found <- locate_students(submissions_path, layout)
  dir <- found$dir
  students <- found$students
  if (length(students) == 0) {
    warning("No student folders found in: ", submissions_path)
    return(empty_grade_results())
  }

  exercises <- expected_exercises(test_dir)
  if (length(exercises) == 0) {
    warning("No test files found in: ", test_dir)
    return(empty_grade_results())
  }
  # Check every test file once, before grading anyone: a broken one stops
  # here, and a file without tests warns once instead of once per student.
  for (ex in exercises) discover_test_fns(find_test_file(ex, test_dir), ex)

  use_cli <- requireNamespace("cli", quietly = TRUE) && length(students) > 1
  progress_id <- if (use_cli) {
    cli::cli_progress_bar("Grading", total = length(students), clear = FALSE,
                          .auto_close = FALSE)
  } else NULL

  display <- display_names(students, student_name_fn)

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
        results[[i]] <- quiet_no_tests(grade_exercise(
          file, test_dir = test_dir, timeout = timeout, student = name,
          engine = "inproc", allow_masking = allow_masking
        ))
      } else {
        job <- quiet_no_tests(start_grading_callr(
          file, find_test_file(tasks$exercise[[i]], test_dir),
          timeout, name, protected, allow_masking,
          mode = engine
        ))
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
  out <- new_grade_results(combined)
  # Each student's submission folder, for export_moodle_feedback().
  attr(out, "folders") <- stats::setNames(students, display)
  out
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
    error = function(e) list(value = NULL, err = e),
    # testthat::skip() is not an error; record it so the teacher sees it.
    skip = function(e) {
      list(value = NULL, err = simpleError(paste(
        "test skipped:", sub("^Reason: ", "", conditionMessage(e)))))
    }
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
copy_student_objects <- function(from, to, protected, allow = character()) {
  nms <- ls(from, all.names = TRUE)
  masked <- union(intersect(nms, protected),
                  setdiff(grep(comparison_methods, nms, value = TRUE), allow))
  for (nm in setdiff(nms, masked)) assign(nm, get(nm, envir = from), envir = to)
  is_stub <- vapply(masked, function(nm) {
    isTRUE(attr(get(nm, envir = from), "corrector_stub"))
  }, logical(1))
  masked[!is_stub]
}

add_masking_note <- function(df, masked) {
  add_note(df, "ignored student definitions that mask base functions: ", masked)
}

add_note <- function(df, prefix, items) {
  if (length(items) == 0 || nrow(df) == 0) return(df)
  note <- paste0(prefix, paste(items, collapse = ", "))
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

is_time_limit <- function(msg) grepl("elapsed time limit|CPU time limit", msg)

load_timeout_result <- function(student, exercise, test_fns, timeout) {
  new_grade_results(data.frame(
    student  = student,
    exercise = exercise,
    test     = test_fns,
    status   = "timeout",
    message  = sprintf("student file took longer than %g s to load", timeout),
    duration = NA_real_,
    stringsAsFactors = FALSE
  ))
}

# quit() and q() in student code would end the grading session. The stubs
# are marked so they are not reported as masked base functions.
add_quit_stubs <- function(env) {
  stub <- function(...) stop("quit() is not allowed while grading", call. = FALSE)
  attr(stub, "corrector_stub") <- TRUE
  assign("quit", stub, envir = env)
  assign("q", stub, envir = env)
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
  src <- tryCatch({source(test_file, local = env, encoding = source_encoding(test_file)); TRUE},
                  error = function(e) conditionMessage(e))
  if (!isTRUE(src)) {
    stop("Test file ", basename(test_file), " could not be loaded: ", src,
         call. = FALSE)
  }
  prefix <- paste0("test_", exercise, "_")
  fns <- ls(envir = env)
  fns <- fns[startsWith(fns, prefix)]
  if (length(fns) == 0) {
    warning(structure(
      class = c("corrector_no_tests", "warning", "condition"),
      list(message = paste0("No functions named ", prefix, "* in ",
                            basename(test_file)), call = NULL)
    ))
  }
  fns
}

check_test_dir <- function(test_dir) {
  if (!dir.exists(test_dir)) stop("test_dir does not exist: ", test_dir, call. = FALSE)
}

check_timeout <- function(timeout) {
  if (!is.numeric(timeout) || length(timeout) != 1 || is.na(timeout) || timeout <= 0) {
    stop("timeout must be a positive number of seconds (or Inf)", call. = FALSE)
  }
}

# grade_submissions() already warned once per test file without tests.
quiet_no_tests <- function(expr) {
  withCallingHandlers(expr, corrector_no_tests = function(w) {
    invokeRestart("muffleWarning")
  })
}

# The folder that holds the student folders, and their names. Used by
# grade_submissions() and compare_submissions().
locate_students <- function(submissions_path, layout) {
  dir <- normalizePath(extract_if_zip(submissions_path))
  if (layout == "moodle") dir <- moodle_to_folders(dir)
  students <- student_dirs(dir)
  # A zip of the parent folder holds one folder with the student folders inside.
  if (length(students) == 1 &&
      length(list.files(file.path(dir, students), pattern = "\\.(r|rmd|qmd)$",
                 ignore.case = TRUE)) == 0 &&
      length(student_dirs(file.path(dir, students))) > 0) {
    dir <- file.path(dir, students)
    students <- student_dirs(dir)
  }
  list(dir = dir, students = students)
}

# Display names; folders that map to the same name keep their folder name.
display_names <- function(students, student_name_fn) {
  display <- vapply(students, student_name_fn, character(1), USE.NAMES = FALSE)
  clash <- duplicated(display) | duplicated(display, fromLast = TRUE)
  if (any(clash)) {
    warning("Folders with the same display name; using folder names instead: ",
            paste(students[clash], collapse = ", "))
    display[clash] <- students[clash]
  }
  display
}

# Sub-folders of `dir`, without hidden folders or macOS zip metadata.
student_dirs <- function(dir) {
  dirs <- list.dirs(dir, full.names = FALSE, recursive = FALSE)
  dirs[!startsWith(dirs, ".") & dirs != "__MACOSX"]
}

extract_if_zip <- function(path) {
  if (identical(tolower(tools::file_ext(path)), "zip")) {
    # Refuse entries such as "../x" or "/x" that would land outside `dest`.
    entries <- utils::unzip(path, list = TRUE)$Name
    unsafe <- grepl("^([/\\\\]|[A-Za-z]:)", entries) |
      vapply(strsplit(entries, "[/\\\\]"), function(p) any(p == ".."), logical(1))
    if (any(unsafe)) {
      stop("Zip has entries that point outside the extraction folder: ",
           paste(entries[unsafe], collapse = ", "))
    }
    dest <- file.path(tempdir(), paste0("corrector_", basename(tools::file_path_sans_ext(path))))
    unlink(dest, recursive = TRUE)
    dir.create(dest, recursive = TRUE)
    unzip(path, exdir = dest)
    return(dest)
  }
  path
}

#' Extractor por defecto del nombre del estudiante
#'
#' Divide el nombre de la carpeta en los guiones bajos, toma la primera
#' parte, la pasa a minúsculas y después le aplica [tools::toTitleCase()].
#' Ejemplos: `"garcia_juan_12345"` da `"Garcia"`; `"lopez"` da `"Lopez"`.
#'
#' @section English:
#' **Default student-name extractor.** Splits the folder name on underscores,
#' takes the first segment, lower-cases it, then applies
#' [tools::toTitleCase()]. Examples: `"garcia_juan_12345"` becomes `"Garcia"`;
#' `"lopez"` becomes `"Lopez"`.
#'
#' @param folder Texto. Nombre de la carpeta de la entrega.
#'   *English:* Character. Submission folder name.
#' @return Texto. Nombre para mostrar.
#'   *English:* Character. Display name.
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
