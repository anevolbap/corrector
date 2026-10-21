test_that("zip entries that escape the extraction folder are refused", {
  root <- withr::local_tempdir()
  inner <- file.path(root, "src", "inner")
  dir.create(inner, recursive = TRUE)
  writeLines("x", file.path(root, "src", "evil.txt"))
  writeLines("sumar <- function(a, b) a + b", file.path(inner, "ejercicio1.R"))
  zip_path <- file.path(root, "evil.zip")
  withr::with_dir(inner, utils::zip(zip_path, c("ejercicio1.R", "../evil.txt"),
                                    flags = "-q"))
  expect_error(extract_if_zip(zip_path), "outside")
})

make_student <- function(envir = parent.frame()) {
  subs <- withr::local_tempdir(.local_envir = envir)
  for (s in c("ana", "beto")) {
    dir.create(file.path(subs, s))
    writeLines("sumar <- function(a, b) a + b", file.path(subs, s, "ejercicio1.R"))
  }
  subs
}

for (engine in c("callr", "inproc")) {
  test_that(paste("a broken test file stops grading, engine", engine), {
    tests <- withr::local_tempdir()
    writeLines(c("test_ejercicio1_a <- function() sumar(1, 1) == 2", "this is ( broken"),
               file.path(tests, "test_ejercicio1.R"))
    subs <- make_student()
    expect_error(
      grade_exercise(file.path(subs, "ana", "ejercicio1.R"), tests, engine = engine),
      "test_ejercicio1.R could not be loaded"
    )
    expect_error(
      suppressMessages(grade_submissions(subs, tests, engine = engine)),
      "test_ejercicio1.R could not be loaded"
    )
  })

  test_that(paste("a test file without test functions warns once, engine", engine), {
    tests <- withr::local_tempdir()
    writeLines("ayuda <- function() 1", file.path(tests, "test_ejercicio1.R"))
    subs <- make_student()
    warnings <- character()
    withCallingHandlers(
      suppressMessages(grade_submissions(subs, tests, engine = engine)),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    expect_length(warnings, 1)
    expect_match(warnings, "test_ejercicio1_")
  })
}

test_that("export_to_csv does not write live spreadsheet formulas", {
  res <- new_grade_results(data.frame(
    student = c("=cmd", "Ana"), exercise = "e1", test = "test_e1_a",
    status = "error",
    message = c('=HYPERLINK("http://x","click")', "plain message"),
    duration = 0, stringsAsFactors = FALSE
  ))
  path <- withr::local_tempfile(fileext = ".csv")
  export_to_csv(res, path, format = "long")
  out <- read.csv(path)
  expect_equal(out$message, c("'=HYPERLINK(\"http://x\",\"click\")", "plain message"))
  expect_equal(out$student, c("'=cmd", "Ana"))
})
