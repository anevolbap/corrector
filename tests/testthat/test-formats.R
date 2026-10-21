rmd_lines <- c(
  "---",
  "title: Ejercicio 1",
  "---",
  "",
  "Mi solucion:",
  "",
  "```{r}",
  "sumar <- function(a, b) a + b",
  "```"
)

for (engine in c("callr", "inproc")) {
  for (ext in c("Rmd", "qmd")) {
    test_that(paste("grades", ext, "submissions, engine", engine), {
      skip_if_not_installed("knitr")
      dir  <- withr::local_tempdir()
      file <- file.path(dir, paste0("ejercicio1.", ext))
      writeLines(rmd_lines, file)
      res <- grade_exercise(file, test_path("fixtures/tests"), engine = engine)
      expect_equal(unique(res$exercise), "ejercicio1")
      expect_true(all(res$status == "pass"))
    })
  }
}

test_that("student file names match exercises regardless of case", {
  subs <- withr::local_tempdir()
  dir.create(file.path(subs, "ana"))
  writeLines("sumar <- function(a, b) a + b", file.path(subs, "ana", "Ejercicio1.R"))
  res <- suppressMessages(grade_submissions(subs, test_path("fixtures/tests")))
  expect_equal(unique(res$exercise), "ejercicio1")
  expect_true(all(res$status == "pass"))
})

test_that("grade_submissions picks up an Rmd submission", {
  skip_if_not_installed("knitr")
  subs <- withr::local_tempdir()
  dir.create(file.path(subs, "ana"))
  writeLines(rmd_lines, file.path(subs, "ana", "ejercicio1.Rmd"))
  res <- suppressMessages(grade_submissions(subs, test_path("fixtures/tests")))
  expect_true(all(res$status == "pass"))
})
