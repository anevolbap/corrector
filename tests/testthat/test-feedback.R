test_that("export_feedback writes one Markdown file per student", {
  res <- new_grade_results(data.frame(
    student  = c("Ana Gomez", "Ana Gomez", "Beto"),
    exercise = c("e1", "e1", "e1"),
    test     = c("test_e1_a", "test_e1_b", NA),
    status   = c("pass", "error", "source_error"),
    message  = c(NA, "objeto 'x' no encontrado", "unexpected symbol"),
    duration = 0,
    stringsAsFactors = FALSE
  ))
  dir <- withr::local_tempdir()
  paths <- export_feedback(res, dir, lang = "en")
  expect_setequal(basename(paths), c("Ana Gomez.md", "Beto.md"))

  ana <- readLines(file.path(dir, "Ana Gomez.md"))
  expect_true(any(grepl("^# Ana Gomez", ana)))
  expect_true(any(grepl("50%", ana)))
  expect_true(any(grepl("test_e1_b.*error", ana)))
  expect_true(any(grepl("objeto 'x' no encontrado", ana, fixed = TRUE)))

  beto <- readLines(file.path(dir, "Beto.md"))
  expect_true(any(grepl("source_error", beto)))
})

fb_results <- function() {
  new_grade_results(data.frame(
    student = "Ana", exercise = "e1", test = c("test_e1_a", "test_e1_b", NA),
    status = c("pass", "fail", "missing"), message = NA_character_, duration = 0,
    stringsAsFactors = FALSE
  ))
}

test_that("export_feedback writes Spanish or English labels", {
  es <- readLines(export_feedback(fb_results(), withr::local_tempdir(), lang = "es"))
  expect_true(any(grepl("^Nota total: ", es)))
  expect_true(any(grepl("`test_e1_a`: aprobado", es, fixed = TRUE)))
  expect_true(any(grepl("no aprobado", es)))
  expect_true(any(grepl("no entregado", es)))
  en <- readLines(export_feedback(fb_results(), withr::local_tempdir(), lang = "en"))
  expect_true(any(grepl("^Total score: ", en)))
  expect_true(any(grepl("`test_e1_a`: pass", en, fixed = TRUE)))
  expect_error(export_feedback(fb_results(), withr::local_tempdir(), lang = "fr"))
})

test_that("the default language follows the computer, Spanish otherwise", {
  withr::with_envvar(c(LANGUAGE = "en_US"), expect_equal(default_lang(), "en"))
  withr::with_envvar(c(LANGUAGE = "es_AR"), expect_equal(default_lang(), "es"))
  withr::with_envvar(c(LANGUAGE = "fr_FR"), expect_equal(default_lang(), "es"))
  expect_equal(lang_of("English_United States.1252"), "en")
  expect_equal(lang_of("Spanish_Argentina.1252"), "es")
  expect_equal(lang_of("C"), "es")
  expect_equal(lang_of("en_GB.UTF-8"), "en")
})

test_that("export_feedback makes student names safe as file names", {
  res <- example_results()
  res$student[res$student == "Garcia"] <- "Garcia/Juan"
  dir <- withr::local_tempdir()
  paths <- export_feedback(res, dir, lang = "en")
  expect_true(all(file.exists(paths)))
  expect_true("Garcia_Juan.md" %in% basename(paths))
})
