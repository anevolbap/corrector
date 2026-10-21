# corrector 0.5.0

## Breaking changes

* `grade_report()`, `export_to_html()` and `plot_report()` count a missing
  exercise, or one with a `source_error`, as 0. Before, they left it out, so
  a student who handed in 1 of 5 exercises, all correct, showed 100%. The
  student score is now the same as `student_scores()$total`.

# corrector 0.4.0

## New features

* Test functions can use testthat expectations. A failed `expect_*()` is
  recorded as `fail` with its message, and a test whose expectations all
  pass counts as `pass`. Students cannot redefine testthat functions.
* `grade_submissions(layout = "moodle")` reads the export from Moodle's
  "Download all submissions", with or without "Download submissions in
  folders". New `moodle_student_name()`.
* New `student_scores()`: partial credit per exercise, weights per test or
  per exercise, and a `total` where missing exercises count as 0.
  `grade_report()` gains `scoring` and `weights`; its defaults are unchanged.
* New `export_feedback()` writes one Markdown file per student.
* Students can hand in `.Rmd` or `.qmd` files; their R chunks are graded.
* Student and test file names are matched ignoring case.
* `export_to_html()` and `plot_report()` gain `scoring` and `weights`, like
  `grade_report()`.

## Hardening

* Tests look up names in the attached packages instead of the global
  environment, so a student can no longer forge passes by assigning
  functions there.
* The callr engine discards student output. Before, more than about 64 KB of
  printed output stalled the subprocess, and every test timed out.
* The time limit also applies while loading the student's file. A file that
  never finishes loading gives `timeout` on every test; before, the inproc
  engine hung.
* `quit()` and `q()` in student code raise an error instead of ending the
  session. The inproc engine restores the working directory and options.
* When the callr engine kills an exercise, tests that already finished keep
  their result.
* A test file that fails to load stops grading with a clear error before
  anyone is graded; before, the callr engine returned zero rows in silence. A
  test file without `test_<exercise>_*` functions warns once.
* testthat `skip()` in a test is recorded as `error` instead of aborting.
* Zip entries that point outside the extraction folder are refused.
* CSV and Google Sheets exports put a `'` before text that a spreadsheet
  would run as a formula.
* Clear errors for missing paths and bad `timeout` or `workers` values, and
  a warning when there are no student folders.
* Fixed edge cases: `NA` student names, a single student folder with only
  `.Rmd` files, empty results in `grade_report()` and `plot_report()`,
  colliding feedback file names, and exercises named `student` or `total`.

## Other

* The three pattern arguments listed by mistake in the 0.2.0 notes
  (`exercise_pattern`, `test_file_template`, `test_fn_pattern`) will not be
  added: exercise names already come from the test file names.

# corrector 0.3.1

* Fixed: student and test code could only use base R. Calls such as
  `median()`, `sd()`, `rnorm()` or `head()` failed with "could not find
  function", and `library()` in a test file had no effect. Code now sees the
  attached packages.
* Every exported function has examples.
* A pkgdown site is built and deployed to
  <https://anevolbap.github.io/corrector/>.
* DESCRIPTION describes the current per-test results and the callr engine.
* Prepared for the first CRAN submission (`cran-comments.md`).

# corrector 0.3.0

## Breaking changes

* The default engine is now `"callr"` and the default `timeout` is 10 seconds
  per test, for both `grade_exercise()` and `grade_submissions()`. Pass
  `engine = "inproc"` and `timeout = Inf` for the old behavior. `callr` moved
  from Suggests to Imports.

## New features

* `grade_submissions(workers = )` runs several callr subprocesses at the same
  time. Results keep the same order as with one worker.
* The callr subprocess runs in its own temporary working directory, so files
  a student writes do not land in your folder.

## Bug fixes

* The callr engine now warns on `source_error`, like the inproc engine.
* The callr engine returns zero rows instead of an error when a test file
  defines no test functions for the exercise.

## Other

* CI checks on macOS and Windows, and a coverage workflow runs covr.
* The READMEs and the vignette say that corrector is not a security sandbox.

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
