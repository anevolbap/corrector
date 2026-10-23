make_moodle_tests <- function(envir = parent.frame()) {
  td <- withr::local_tempdir(.local_envir = envir)
  writeLines('test_ejercicio1_suma <- function() sumar(2, 3) == 5',
             file.path(td, "test_ejercicio1.R"))
  td
}

test_that("moodle_student_name strips the id and plugin suffix", {
  expect_equal(moodle_student_name("Juan Perez_123456_assignsubmission_file"),
               "Juan Perez")
  expect_equal(moodle_student_name("Ana Maria Gomez_77_assignsubmission_file_"),
               "Ana Maria Gomez")
})

test_that("layout = 'moodle' reads the folder export and skips online text", {
  subs <- withr::local_tempdir()
  ana  <- file.path(subs, "Ana Gomez_101_assignsubmission_file")
  beto <- file.path(subs, "Beto Diaz_102_assignsubmission_file")
  dir.create(ana)
  dir.create(beto)
  dir.create(file.path(subs, "Ana Gomez_101_assignsubmission_onlinetext"))
  writeLines("<p>hola</p>", file.path(subs, "Ana Gomez_101_assignsubmission_onlinetext",
                                      "onlinetext.html"))
  writeLines("sumar <- function(a, b) a + b", file.path(ana, "ejercicio1.R"))
  writeLines("sumar <- function(a, b) a - b", file.path(beto, "ejercicio1.R"))

  res <- suppressMessages(grade_submissions(subs, make_moodle_tests(),
                                            layout = "moodle"))
  expect_setequal(unique(res$student), c("Ana Gomez", "Beto Diaz"))
  expect_equal(as.character(res$status[res$student == "Ana Gomez"]), "pass")
  expect_equal(as.character(res$status[res$student == "Beto Diaz"]), "fail")
})

moodle_results <- function(envir = parent.frame()) {
  subs <- withr::local_tempdir(.local_envir = envir)
  for (who in c("Ana Gomez_101", "Beto Diaz_102")) {
    d <- file.path(subs, paste0(who, "_assignsubmission_file"))
    dir.create(d)
    writeLines("sumar <- function(a, b) a + b", file.path(d, "ejercicio1.R"))
  }
  suppressMessages(grade_submissions(subs, make_moodle_tests(envir), layout = "moodle"))
}

test_that("export_moodle_feedback writes the zip Moodle imports", {
  skip_if(Sys.which("zip") == "", "no zip program")
  res <- moodle_results()
  zip_path <- withr::local_tempfile(fileext = ".zip")
  out <- export_moodle_feedback(res, zip_path, lang = "es")
  expect_equal(normalizePath(out), normalizePath(zip_path))
  entries <- utils::unzip(zip_path, list = TRUE)$Name
  expect_setequal(entries, c("Ana Gomez_101_assignsubmission_file/devolucion.md",
                             "Beto Diaz_102_assignsubmission_file/devolucion.md"))
  dir <- withr::local_tempdir()
  utils::unzip(zip_path, exdir = dir)
  ana <- readLines(file.path(dir, "Ana Gomez_101_assignsubmission_file", "devolucion.md"))
  expect_true(any(grepl("^# Ana Gomez", ana)))
})

test_that("export_moodle_feedback names the file in the chosen language", {
  skip_if(Sys.which("zip") == "", "no zip program")
  zip_path <- withr::local_tempfile(fileext = ".zip")
  export_moodle_feedback(moodle_results(), zip_path, lang = "en")
  expect_true(all(grepl("/feedback\\.md$", utils::unzip(zip_path, list = TRUE)$Name)))
})

test_that("export_moodle_feedback needs results graded with layout = 'moodle'", {
  expect_error(export_moodle_feedback(example_results(), tempfile(fileext = ".zip")),
               "layout = \"moodle\"")
})

test_that("layout = 'moodle' reads the flat export from a zip", {
  subs <- withr::local_tempdir()
  writeLines("sumar <- function(a, b) a + b",
             file.path(subs, "Ana Gomez_101_assignsubmission_file_ejercicio1.R"))
  writeLines("sumar <- function(a, b) a - b",
             file.path(subs, "Beto Diaz_102_assignsubmission_file_ejercicio1.R"))
  zip_path <- withr::local_tempfile(fileext = ".zip")
  withr::with_dir(subs, utils::zip(zip_path, list.files(), flags = "-q"))

  res <- suppressMessages(grade_submissions(zip_path, make_moodle_tests(),
                                            layout = "moodle"))
  expect_setequal(unique(res$student), c("Ana Gomez", "Beto Diaz"))
  expect_equal(as.character(res$status[res$student == "Ana Gomez"]), "pass")
})
