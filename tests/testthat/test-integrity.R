integrity_tests <- function(envir = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = envir)
  writeLines(c(
    "test_ejercicio1_suma <- function() sumar(2, 3) == 5",
    "test_ejercicio1_igual <- function() isTRUE(all.equal(sumar(1, 1), 2))"
  ), file.path(td, "test_ejercicio1.R"))
  td
}

student_file <- function(lines, envir = parent.frame()) {
  dir <- withr::local_tempdir(.local_envir = envir)
  writeLines(lines, file.path(dir, "ejercicio1.R"))
  file.path(dir, "ejercicio1.R")
}

drop_attached <- function() {
  while ("trampa" %in% search()) detach("trampa", character.only = TRUE)
}

test_that("scan_code finds suspicious calls with line numbers", {
  file <- student_file(c(
    "sumar <- function(a, b) a + b",
    'attach(list(x = 1), name = "trampa")',
    'assign("isTRUE", function(x) TRUE, envir = globalenv())',
    "unlockBinding('==', baseenv())"
  ))
  found <- scan_code(file)
  expect_match(found, "attach\\(\\) at line 2", all = FALSE)
  expect_match(found, "assign\\(\\) into globalenv at line 3", all = FALSE)
  expect_match(found, "unlockBinding\\(\\) at line 4", all = FALSE)
})

test_that("scan_code is quiet on ordinary code", {
  file <- student_file(c(
    "sumar <- function(a, b) {",
    "  x <- get('a')",
    "  assign('y', 1)",
    "  x + b",
    "}"
  ))
  expect_length(scan_code(file), 0)
})

for (engine in c("callr", "inproc")) {
  test_that(paste("comparison methods from student code are not used, engine", engine), {
    file <- student_file(c(
      "Ops.trampa <- function(e1, e2) TRUE",
      "all.equal.trampa <- function(target, current, ...) TRUE",
      'sumar <- function(a, b) structure(0, class = "trampa")'
    ))
    res <- grade_exercise(file, integrity_tests(), engine = engine)
    expect_true(all(res$status == "fail"))
    expect_match(res$message, "Ops.trampa", fixed = TRUE, all = TRUE)
  })

  test_that(paste("allow_masking lets a comparison method through, engine", engine), {
    file <- student_file(c(
      "Ops.dinero <- function(e1, e2) get(.Generic)(unclass(e1), unclass(e2))",
      'sumar <- function(a, b) structure(a + b, class = "dinero")'
    ))
    res <- grade_exercise(file, integrity_tests(), engine = engine,
                          allow_masking = "Ops.dinero")
    expect_equal(as.character(res$status[res$test == "test_ejercicio1_suma"]), "pass")
  })

  test_that(paste("suspicious code and tampering are noted, engine", engine), {
    file <- student_file(c(
      'attach(list(isTRUE = function(x) TRUE), name = "trampa")',
      'registerS3method("all.equal", "trampa2", function(target, current, ...) TRUE)',
      "sumar <- function(a, b) a + b"
    ))
    res <- grade_exercise(file, integrity_tests(), engine = engine)
    drop_attached()
    expect_match(res$message, "suspicious code: attach() at line 1", fixed = TRUE, all = TRUE)
    expect_match(res$message, "tampering: attached trampa", fixed = TRUE, all = TRUE)
    expect_match(res$message, "all.equal.trampa2", fixed = TRUE, all = TRUE)
  })

  test_that(paste("clean code gets no notes, engine", engine), {
    res <- grade_exercise(test_path("fixtures/student_ok/ejercicio1.R"),
                          integrity_tests(), engine = engine)
    expect_true(all(is.na(res$message)))
  })
}

test_that("inproc undoes a student's attach() and registered methods", {
  file <- student_file(c(
    'attach(list(isTRUE = function(x) TRUE), name = "trampa")',
    'registerS3method("all.equal", "trampa3", function(target, current, ...) TRUE)',
    "sumar <- function(a, b) a + b"
  ))
  suppressMessages(grade_exercise(file, integrity_tests(), engine = "inproc"))
  expect_false("trampa" %in% search())
  table <- get(".__S3MethodsTable__.", envir = baseenv())
  expect_false(exists("all.equal.trampa3", envir = table, inherits = FALSE))
})

test_that("inproc warns when student code replaces a base function", {
  original <- base::isFALSE
  on.exit({
    unlockBinding("isFALSE", baseenv())
    assign("isFALSE", original, envir = baseenv())
    lockBinding("isFALSE", baseenv())
  })
  file <- student_file(c(
    'unlockBinding("isFALSE", baseenv())',
    'assign("isFALSE", function(x) TRUE, envir = baseenv())',
    "sumar <- function(a, b) a + b"
  ))
  expect_warning(
    res <- grade_exercise(file, integrity_tests(), engine = "inproc"),
    "replaced base functions in this R session: isFALSE"
  )
  expect_match(res$message, "changed base functions isFALSE", fixed = TRUE, all = TRUE)
})

test_that("a killed isolated job does not trust the progress file", {
  fake_job <- function(isolated) {
    progress <- withr::local_tempfile(fileext = ".rds", .local_envir = parent.frame(2))
    ok <- list(v = TRUE, err = NULL, failed = FALSE, n_ok = 0L, duration = 0)
    saveRDS(list(results = list(test_ejercicio1_a = ok), masked = character()), progress)
    list(proc = callr::r_bg(function() Sys.sleep(60)), deadline = 0,
         progress = progress, isolated = isolated, suspicious = character(),
         file = "ejercicio1.R", test_fns = "test_ejercicio1_a", timeout = 1,
         student = "Ana", exercise = "ejercicio1")
  }
  expect_equal(as.character(finish_grading_callr(fake_job(FALSE))$status), "pass")
  expect_equal(as.character(finish_grading_callr(fake_job(TRUE))$status), "timeout")
})

test_that("grade_report lists students with suspicious code or tampering", {
  res <- example_results()
  res$message[res$student == "Lopez"] <- "suspicious code: attach() at line 2"
  out <- capture.output(print(grade_report(res)))
  expect_true(any(grepl("Check by hand", out)))
  expect_true(any(grepl("Lopez", out[grep("Check by hand", out):length(out)])))
})
