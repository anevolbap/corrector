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
