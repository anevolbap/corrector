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
