sample_results <- function() {
  new_grade_results(data.frame(
    student  = c("Alice", "Alice", "Bob", "Bob"),
    exercise = c("ejercicio1", "ejercicio2", "ejercicio1", "ejercicio2"),
    test     = c("test_ejercicio1_a", "test_ejercicio2_a",
                 "test_ejercicio1_a", "test_ejercicio2_a"),
    status   = c("pass", "pass", "fail", "pass"),
    message  = NA_character_,
    duration = 0,
    stringsAsFactors = FALSE
  ))
}

test_that("export_to_csv writes a readable wide file by default", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  results <- sample_results()
  export_to_csv(results, tmp)
  back <- utils::read.csv(tmp, stringsAsFactors = FALSE)
  expect_equal(back$student, c("Alice", "Bob"))
  expect_equal(back$ejercicio1, c(TRUE, FALSE))
})

test_that("export_to_csv supports the long format", {
  tmp <- withr::local_tempfile(fileext = ".csv")
  results <- sample_results()
  export_to_csv(results, tmp, format = "long")
  back <- utils::read.csv(tmp, stringsAsFactors = FALSE)
  expect_setequal(names(back),
                  c("student", "exercise", "test", "status", "message", "duration"))
  expect_equal(nrow(back), 4)
})

test_that("export_to_html writes a file with expected content", {
  tmp <- withr::local_tempfile(fileext = ".html")
  results <- sample_results()
  export_to_html(results, tmp)
  html <- paste(readLines(tmp), collapse = "")
  expect_true(grepl("Alice", html))
  expect_true(grepl("class=\"pass\"", html))
  expect_true(grepl("class=\"fail\"", html))
  expect_true(grepl("Pass rate", html))
})

test_that("export_to_html escapes special characters in student names", {
  tmp <- withr::local_tempfile(fileext = ".html")
  results <- sample_results()
  results$student[results$student == "Alice"] <- "<Alice>"
  export_to_html(results, tmp)
  html <- paste(readLines(tmp), collapse = "")
  expect_true(grepl("&lt;Alice&gt;", html))
  expect_false(grepl("<Alice>", html))
})
