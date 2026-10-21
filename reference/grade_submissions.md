# Grade all student submissions in a directory or zip archive

Expects one sub-folder per student inside `submissions_path`. Every
student is graded on every exercise that has a test file in `test_dir`;
a student who omits an exercise gets a `missing` row.

## Usage

``` r
grade_submissions(
  submissions_path,
  test_dir,
  timeout = 10,
  engine = c("callr", "inproc"),
  student_name_fn = default_student_name,
  allow_masking = character(),
  workers = 1L
)
```

## Arguments

- submissions_path:

  Path to a directory or `.zip` archive of submissions.

- test_dir:

  Directory that contains the test files.

- timeout:

  Maximum seconds allowed per test function. Default 10.

- engine:

  `"callr"` (default) or `"inproc"`. See
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- student_name_fn:

  Function applied to each student folder name to produce the display
  name. Defaults to taking the first underscore- separated token and
  applying title case. Folders that map to the same name keep their
  folder name, with a warning.

- allow_masking:

  Base function names students may redefine. See
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- workers:

  Number of callr subprocesses to run at the same time. Default 1.
  Values above 1 speed up large classes; a value near
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)
  is a good upper bound. Ignored by the `"inproc"` engine.

## Value

A
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object.

## Details

If `submissions_path` ends in `.zip` it is extracted into a
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) subfolder first.
Loose files, hidden folders and `__MACOSX` are ignored. If the path
holds a single folder with no `.R` files but with sub-folders, those
sub-folders are taken as the students.

## Examples

``` r
# One folder per student, one test file per exercise.
root <- file.path(tempdir(), "entregas")
dir.create(file.path(root, "garcia_juan"), recursive = TRUE)
dir.create(file.path(root, "lopez_maria"), recursive = TRUE)
writeLines("ceros_cuadratica <- function(a, b, c) c(-1, 1)",
           file.path(root, "garcia_juan", "ejercicio1.R"))
writeLines("ceros_cuadratica <- function(a, b, c) 0",
           file.path(root, "lopez_maria", "ejercicio1.R"))
tests <- file.path(tempdir(), "tests")
dir.create(tests)
file.copy(system.file("examples", "test_ejercicio1.R", package = "corrector"),
          tests)
#> [1] TRUE
results <- grade_submissions(root, tests)
results
#> <grade_results> 8 rows, 2 students, 1 exercises
#> Status:
#>   pass          4
#>   fail          4
as.data.frame(results, format = "wide")
#>   student ejercicio1
#> 1  Garcia      FALSE
#> 2   Lopez      FALSE
```
