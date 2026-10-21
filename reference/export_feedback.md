# Write one feedback file per student

Writes `<student>.md` into `dir` for every student: the total score, the
score of each exercise, and the status of each test, with the error
message when there is one. Use it to send each student their results.

## Usage

``` r
export_feedback(results, dir, scoring = c("partial", "all"), weights = NULL)
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- dir:

  Folder to write into. Created if needed.

- scoring, weights:

  Passed to
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

## Value

The paths of the written files, invisibly.

## Examples

``` r
dir <- file.path(tempdir(), "feedback")
paths <- export_feedback(example_results(), dir)
writeLines(readLines(paths[[1]]))
#> # Garcia
#> 
#> Total score: 80%
#> 
#> ## ejercicio1: 100%
#> 
#> - `test_ejercicio1_case1`: pass
#> 
#> ## ejercicio2: 100%
#> 
#> - `test_ejercicio2_case1`: pass
#> 
#> ## ejercicio3: 100%
#> 
#> - `test_ejercicio3_case1`: pass
#> 
#> ## ejercicio4: 0%
#> 
#> - `test_ejercicio4_case1`: fail
#> 
#> ## ejercicio5: 100%
#> 
#> - `test_ejercicio5_case1`: pass
#> 
```
