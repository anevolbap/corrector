test_that("grade_scale maps 0-1 scores to a 1-10 grade with 60% for a 4", {
  expect_equal(grade_scale(c(0, 0.6, 1)), c(1, 4, 10))
  expect_equal(grade_scale(0.8), 7)
  expect_equal(grade_scale(0.3, digits = 1), 2.5)
})

test_that("rounding never lifts a failing score to the pass mark", {
  # 0.59 maps to 3.95, which would round to 4.
  expect_equal(grade_scale(0.59), 3)
  expect_equal(grade_scale(0.599, digits = 1), 3.9)
  expect_equal(grade_scale(0.6), 4)
})

test_that("grade_scale takes other scales and keeps NA", {
  expect_equal(grade_scale(c(0, 0.5, 1), min = 0, max = 100, pass = 50, pass_at = 0.5),
               c(0, 50, 100))
  expect_equal(grade_scale(c(NA, 1)), c(NA, 10))
})

test_that("grade_scale rejects bad input", {
  expect_error(grade_scale(1.2), "between 0 and 1")
  expect_error(grade_scale(0.5, pass = 11), "pass")
  expect_error(grade_scale(0.5, pass_at = 1), "pass_at")
})
