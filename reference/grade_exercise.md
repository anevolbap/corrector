# Grade a single exercise file against its tests

Sources the student's file and the matching test file into an isolated
environment, runs every function whose name starts with
`test_<exercise>_`, and returns the per-test outcome as a
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object.

## Usage

``` r
grade_exercise(
  file,
  test_dir,
  timeout = 10,
  student = NA_character_,
  engine = c("callr", "inproc"),
  allow_masking = character()
)
```

## Arguments

- file:

  Path to the student's R file (e.g. `"ejercicio1.R"`).

- test_dir:

  Directory that contains the test files.

- timeout:

  Maximum seconds allowed per test function. Tests that exceed this
  limit are recorded with status `timeout`. Default 10. Use `Inf` for no
  limit.

- student:

  Optional student display name. Defaults to `NA`.

- engine:

  `"callr"` (default) runs each exercise in a fresh R subprocess via the
  callr package, with a temporary working directory. The timeout is a
  hard wall-clock limit, and assignments with `<<-` or files the student
  writes do not reach your session or folder. `"inproc"` runs tests in
  the current R session. It is faster, but its
  [`setTimeLimit()`](https://rdrr.io/r/base/setTimeLimit.html) timeout
  does not interrupt every kind of loop, and student code can see and
  change your global environment.

- allow_masking:

  Character vector of function names from base R and the default
  packages (stats, utils, methods, graphics, grDevices) that the student
  may redefine, e.g. `"factorial"` when the exercise asks for it. Any
  other student object with such a name is not visible to the tests, so
  a student cannot pass by redefining
  [`all()`](https://rdrr.io/r/base/all.html) or `==`. Ignored names are
  listed in the `message` column.

## Value

A
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object with one row per test. If the student file fails to parse, one
row with `status = source_error`. If no matching test file is found, one
row with `status = missing` and a warning.

## Examples

``` r
# The package ships test files for five sample exercises.
tests <- system.file("examples", package = "corrector")
file <- file.path(tempdir(), "ejercicio1.R")
writeLines(c(
  "ceros_cuadratica <- function(a, b, c) {",
  "  d <- sqrt(b^2 - 4 * a * c)",
  "  c((-b - d) / (2 * a), (-b + d) / (2 * a))",
  "}"
), file)
grade_exercise(file, tests, student = "Garcia")
#> <grade_results> 4 rows, 1 students, 1 exercises
#> Status:
#>   pass          3
#>   fail          1
```
