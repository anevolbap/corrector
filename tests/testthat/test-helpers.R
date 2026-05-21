test_that("default_student_name handles common cases", {
  expect_equal(default_student_name("garcia_juan_12345"), "Garcia")
  expect_equal(default_student_name("lopez"), "Lopez")
  expect_equal(default_student_name("GARCIA_JUAN"), "Garcia")
  expect_equal(default_student_name("perez"), "Perez")
})

test_that("as.data.frame(format='wide') marks errors as NA", {
  res <- new_grade_results(data.frame(
    student  = c("Alice", "Bob"),
    exercise = "ejercicio1",
    test     = c("test_ejercicio1_a", NA),
    status   = c("pass", "source_error"),
    message  = c(NA, "boom"),
    duration = c(0.1, NA),
    stringsAsFactors = FALSE
  ))
  wide <- as.data.frame(res, format = "wide")
  expect_true(wide$ejercicio1[wide$student == "Alice"])
  expect_true(is.na(wide$ejercicio1[wide$student == "Bob"]))
})

test_that("example_results is a grade_results", {
  ex <- example_results()
  expect_s3_class(ex, "grade_results")
  expect_true(all(c("pass", "fail") %in% unique(as.character(ex$status))))
})
