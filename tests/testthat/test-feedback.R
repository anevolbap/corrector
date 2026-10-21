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
  paths <- export_feedback(res, dir)
  expect_setequal(basename(paths), c("Ana Gomez.md", "Beto.md"))

  ana <- readLines(file.path(dir, "Ana Gomez.md"))
  expect_true(any(grepl("^# Ana Gomez", ana)))
  expect_true(any(grepl("50%", ana)))
  expect_true(any(grepl("test_e1_b.*error", ana)))
  expect_true(any(grepl("objeto 'x' no encontrado", ana, fixed = TRUE)))

  beto <- readLines(file.path(dir, "Beto.md"))
  expect_true(any(grepl("source_error", beto)))
})

test_that("export_feedback makes student names safe as file names", {
  res <- example_results()
  res$student[res$student == "Garcia"] <- "Garcia/Juan"
  dir <- withr::local_tempdir()
  paths <- export_feedback(res, dir)
  expect_true(all(file.exists(paths)))
  expect_true("Garcia_Juan.md" %in% basename(paths))
})
