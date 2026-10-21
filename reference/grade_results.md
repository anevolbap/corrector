# Grading results object

A `grade_results` object is a data frame in long format with one row per
(student, exercise, test) and the following columns:

- `student`:

  Character. Student display name.

- `exercise`:

  Character. Exercise identifier (file stem).

- `test`:

  Character. Test function name, or `NA` when the row records a
  `missing` submission or a `source_error`.

- `status`:

  Factor with levels `pass`, `fail`, `error`, `timeout`, `missing`,
  `source_error`.

- `message`:

  Character. Error message when `status` is `error`, `source_error`, or
  `timeout`; `NA` otherwise.

- `duration`:

  Numeric. Seconds elapsed running the test, or `NA` when the test was
  not run.

## Details

Use [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) with
`format = "wide"` to get the old wide-boolean view (one logical column
per exercise, `TRUE` iff all tests passed).
