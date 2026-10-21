make_scored <- function() {
  new_grade_results(data.frame(
    student  = c("Ana", "Ana", "Ana", "Beto", "Beto", "Beto"),
    exercise = c("e1", "e1", "e2", "e1", "e1", "e2"),
    test     = c("test_e1_a", "test_e1_b", "test_e2_a", "test_e1_a", "test_e1_b", NA),
    status   = c("pass", "fail", "pass", "pass", "pass", "missing"),
    message  = NA_character_,
    duration = 0,
    stringsAsFactors = FALSE
  ))
}

test_that("student_scores gives partial credit per exercise", {
  s <- student_scores(make_scored())
  expect_equal(s$e1, c(0.5, 1))
  expect_equal(s$e2, c(1, NA))
  # Missing exercises count as 0 in the total.
  expect_equal(s$total, c(0.75, 0.5))
})

test_that("student_scores with scoring = 'all' matches the wide view", {
  res <- make_scored()
  s <- student_scores(res, scoring = "all")
  wide <- as.data.frame(res, format = "wide")
  expect_equal(s$e1, as.numeric(wide$e1))
  expect_equal(s$e2, as.numeric(wide$e2))
})

test_that("weights apply to tests and to exercises", {
  s <- student_scores(make_scored(), weights = c(test_e1_a = 3, e2 = 2))
  expect_equal(s$e1, c(0.75, 1))
  expect_equal(s$total, c((0.75 + 2 * 1) / 3, (1 + 0) / 3))
})

test_that("unknown weight names warn", {
  expect_warning(student_scores(make_scored(), weights = c(nope = 2)), "nope")
})

test_that("grade_report defaults are unchanged and accept partial scoring", {
  res <- make_scored()
  old <- grade_report(res)
  expect_equal(unname(old$score_by_student), c(0.5, 1))
  part <- grade_report(res, scoring = "partial")
  expect_equal(unname(part$score_by_student), c(0.75, 1))
  expect_equal(unname(part$pass_rate_by_exercise), c(0.75, 1))
})
