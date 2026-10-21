# Setting up a grading pipeline

This vignette walks through a complete grading run end to end: writing
tests, gathering submissions, grading, summarising, and exporting.

## Folder layout

The grader expects one sub-folder per student under a submissions root,
and a flat folder of test files. File names follow a simple convention:

    submissions/
      garcia_juan/
        ejercicio1.R
        ejercicio2.R
      lopez_maria/
        ejercicio1.R
        ejercicio2.R

    tests/
      test_ejercicio1.R
      test_ejercicio2.R

A test file holds one or more functions named `test_<exercise>_<case>`
that return `TRUE` or `FALSE`.

``` r

# tests/test_ejercicio1.R
test_ejercicio1_roots <- function() {
  all(quadratic_roots(1, 0, -1) == c(-1, 1))
}
test_ejercicio1_numeric <- function() {
  is.numeric(quadratic_roots(1, 0, -1))
}
```

## Running the grader

``` r

library(corrector)

results <- grade_submissions("submissions/", test_dir = "tests/")
```

`results` is a `grade_results` object: a long-format data frame with one
row per test, plus the columns `student`, `exercise`, `status`,
`message`, and `duration`. Status is one of `pass`, `fail`, `error`,
`timeout`, `missing`, or `source_error`.

``` r

head(as.data.frame(results, format = "long"))
```

Convert to the legacy wide-boolean view with
`as.data.frame(results, format = "wide")`.

## Summarising

[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
reduces the long results to per-exercise pass rates and per-student
scores, plus counts of errors, timeouts, and missing submissions.

``` r

grade_report(results)
```

[`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
produces three plots. Pass `backend = "ggplot2"` to use ggplot2, if
installed.

## Exporting

``` r

export_to_csv(results, "grades.csv")               # wide by default
export_to_csv(results, "grades-long.csv", format = "long")
export_to_html(results, "report.html")
```

The HTML report colour-codes each cell by status and includes a
per-student breakdown of every test.

## Partial credit, weights and feedback

[`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md)
gives each exercise the fraction of its tests that pass, with optional
weights per test or per exercise, and a `total` grade where a missing
exercise counts as 0. `grade_report(scoring = "partial")` uses the same
rules.
[`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md)
writes one Markdown file per student.

``` r

grades <- student_scores(results, weights = c(ejercicio2 = 2))
export_feedback(results, "feedback/")
```

## testthat, R Markdown and Quarto

Test functions can use testthat expectations
([`library(testthat)`](https://testthat.r-lib.org) at the top of the
test file). Students can hand in `.R`, `.Rmd` or `.qmd` files, and file
names are matched ignoring case.

## Timeouts and untrusted code

The default engine, `"callr"`, runs each exercise in a fresh R
subprocess with a temporary working directory. Each test gets `timeout`
seconds (default 10), and so does loading the student’s file. If a test
does not respond to the limit (for example inside
[`Sys.sleep()`](https://rdrr.io/r/base/Sys.sleep.html)), the subprocess
is killed once the whole exercise passes `timeout` × number of tests + 5
seconds; tests that already finished keep their result. Use
`timeout = Inf` for no limit.

``` r

results <- grade_submissions("submissions/", test_dir = "tests/", timeout = 30)
```

`engine = "inproc"` runs tests in the current R session. It is faster,
but [`setTimeLimit()`](https://rdrr.io/r/base/setTimeLimit.html) does
not interrupt every loop, and student code can change your global
environment.

For large classes, `workers` runs several subprocesses at the same time:

``` r

results <- grade_submissions("submissions/", test_dir = "tests/", workers = 4)
```

corrector is not a sandbox. The `callr` engine protects your R session,
not your computer: student code can read and write any file your user
can, use the network, or run system commands. For code from people you
do not trust, run corrector inside a container or virtual machine
without your credentials. The protection against cheating covers the
common cases (redefining base R functions, writing them into the global
environment, calling [`quit()`](https://rdrr.io/r/base/quit.html)), not
a student who sets out to break the grader, so check odd grades by hand.

## Renaming students

The default student-name extractor takes the first underscore-separated
segment and applies title case (so `garcia_juan_12345` becomes
`Garcia`). Pass `student_name_fn` to override:

``` r

results <- grade_submissions(
  "submissions/", test_dir = "tests/",
  student_name_fn = function(folder) {
    sub("_.*$", "", folder)
  }
)
```

## Moodle

`layout = "moodle"` reads the `.zip` from Moodle’s “Download all
submissions”, with or without “Download submissions in folders”:

``` r

results <- grade_submissions("assignment1.zip", test_dir = "tests/",
                             layout = "moodle")
```
