# corrector 0.2.1

## Bug fixes

* Student code can no longer pass tests by redefining base functions such as
  `all()` or `==`. Tests run in their own environment, and student objects
  that mask a function from base R or the default packages are not visible
  to them. The ignored names are listed in the `message` column. New
  `allow_masking` argument on `grade_exercise()` and `grade_submissions()`
  for exercises that ask students to write such a function (e.g.
  `factorial`).
* The inproc engine no longer runs `test_*` functions defined in the student
  file.
* Students whose folders map to the same display name are no longer merged.
  They keep their folder names, with a warning.
* Latin-1 student files are sourced instead of failing with `source_error`.
* `grade_submissions()` ignores loose files, hidden folders and `__MACOSX`,
  and steps into a single top-level folder (a zipped parent folder).
* `R CMD check` now runs the test suite (`tests/testthat.R` was missing).
* The 0.2.0 notes listed `exercise_pattern`, `test_file_template` and
  `test_fn_pattern` arguments that were never implemented. They are removed
  from the notes below.

# corrector 0.2.0

## Breaking changes

* `grade_exercise()` and `grade_submissions()` now return a `grade_results`
  object: a long-format data frame with one row per test, with columns
  `student`, `exercise`, `test`, `status`, `message`, `duration`. The previous
  wide pass/fail data frame is still available via
  `as.data.frame(results, format = "wide")`.
* `status` is a factor with levels `pass`, `fail`, `error`, `timeout`,
  `missing`, `source_error`. Distinct from the old "all FALSE" collapse.
* `grade_report()`, `plot_report()`, `export_to_csv()`, `export_to_html()`, and
  `export_to_sheets()` consume the new object. CSV defaults to wide for
  backward compatibility; pass `format = "long"` to keep the per-test detail.

## New features

* `engine = "callr"` runs each test in a subprocess via the
  [callr](https://callr.r-lib.org/) package, giving a hard wall-clock timeout
  that actually interrupts busy loops. Default stays `"inproc"`.
* New `student_name_fn` argument on `grade_submissions()`: function applied
  to each student folder name to produce the display name. Defaults to the
  previous "first underscore-separated token, title case" behavior.
* `plot_report(backend = "ggplot2")` produces the three plots with ggplot2 when
  the package is installed; falls back to base R otherwise.
* Progress messages use [cli](https://cli.r-lib.org/) when available.

## Bug fixes

* `find_test_file()` no longer treats the exercise filename as a regex.
* Zip detection is case-insensitive; archives are extracted into `tempdir()`
  rather than next to the input.

# corrector 0.1.0

* First release under the name `corrector` (previously `autocorrectoR`).
