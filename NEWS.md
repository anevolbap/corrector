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
* New arguments on `grade_submissions()`:
  * `exercise_pattern`: regex used to find student exercise files
    (default `"ejercicio"`). Pass `NULL` to accept any `.R` file.
  * `test_file_template`: how test files are named relative to exercise files
    (default `"test_{exercise}"`).
  * `test_fn_pattern`: regex matching test function names inside a test file
    (default `"^test_{exercise}_"`).
  * `student_name_fn`: function applied to each student folder name to produce
    the display name. Defaults to the previous "first underscore-separated
    token, title case" behavior.
* `plot_report(backend = "ggplot2")` produces the three plots with ggplot2 when
  the package is installed; falls back to base R otherwise.
* Progress messages use [cli](https://cli.r-lib.org/) when available.

## Bug fixes

* `find_test_file()` no longer treats the exercise filename as a regex.
* Zip detection is case-insensitive; archives are extracted into `tempdir()`
  rather than next to the input.

# corrector 0.1.0

* First release under the name `corrector` (previously `autocorrectoR`).
