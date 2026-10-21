# Summarise grading results

Computes pass rate per exercise and score per student, plus counts of
errors, timeouts, and missing submissions. The returned object has a
[`print()`](https://rdrr.io/r/base/print.html) method that renders a
readable console summary.

## Usage

``` r
grade_report(results, scoring = c("all", "partial"), weights = NULL)
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object returned by
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  or
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- scoring:

  `"all"` (default): an exercise counts as passed only if every test
  passes. `"partial"`: it scores the fraction of tests that pass. See
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- weights:

  Optional named numeric vector of test or exercise weights. See
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

## Value

A `grade_report` object (a list) with components:

- `pass_rate_by_exercise`:

  Named numeric vector (0-1). Mean exercise score across students.

- `score_by_student`:

  Named numeric vector (0-1). The student's `total` from
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- `overall_mean`:

  Scalar numeric (0-1).

- `issue_counts`:

  Named integer vector with counts of `error`, `timeout`, `missing`, and
  `source_error` rows.

- `flagged`:

  Character vector of students with suspicious code or tampering noted
  in the `message` column (see
  [`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md)).

In `pass_rate_by_exercise` and `score_by_student`, a `missing` exercise
or one with a `source_error` counts as 0.

## Examples

``` r
report <- grade_report(example_results())
report
#> === Grade Report ===
#> 
#> Pass rate by exercise:
#>   ejercicio1                75%
#>   ejercicio2                75%
#>   ejercicio3                62%
#>   ejercicio4                62%
#>   ejercicio5                75%
#> 
#> Overall mean score: 70%
#> 
#> Score by student (descending):
#>   Garcia               ################     80%
#>   Lopez                ################     80%
#>   Martinez             ################     80%
#>   Gonzalez             ################     80%
#>   Rodriguez            ############         60%
#>   Fernandez            ############         60%
#>   Perez                ############         60%
#>   Sanchez              ############         60%
report$score_by_student
#>    Garcia     Lopez  Martinez Rodriguez Fernandez  Gonzalez     Perez   Sanchez 
#>       0.8       0.8       0.8       0.6       0.6       0.8       0.6       0.6 
```
