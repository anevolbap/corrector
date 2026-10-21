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
