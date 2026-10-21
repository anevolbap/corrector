# Score each student, with optional partial credit and weights

Score each student, with optional partial credit and weights

## Usage

``` r
student_scores(results, scoring = c("partial", "all"), weights = NULL)
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- scoring:

  `"partial"` (default): an exercise scores the weighted fraction of its
  tests that pass. `"all"`: an exercise scores 1 only if every test
  passes, else 0.

- weights:

  Optional named numeric vector. A name that matches a test function
  (e.g. `test_ejercicio1_raices`) weights that test inside its exercise.
  A name that matches an exercise (e.g. `ejercicio1`) weights that
  exercise in `total`. Anything not named weighs 1.

## Value

A data frame with one row per student: a `student` column, one numeric
column (0-1) per exercise, and `total`. An exercise is `NA` when it is
`missing` or has a `source_error`; it counts as 0 in `total`.

## Examples

``` r
results <- example_results()
student_scores(results)
#>     student ejercicio1 ejercicio2 ejercicio3 ejercicio4 ejercicio5 total
#> 1    Garcia          1          1          1          0          1   0.8
#> 2     Lopez          1          1          0          1          1   0.8
#> 3  Martinez          1          0          1          1          1   0.8
#> 4 Rodriguez          0          1          1          0          1   0.6
#> 5 Fernandez          1          1          1          0          0   0.6
#> 6  Gonzalez          1          0          1          1          1   0.8
#> 7     Perez          0          1          0          1          1   0.6
#> 8   Sanchez          1          1          0          1          0   0.6
student_scores(results, weights = c(ejercicio5 = 2))
#>     student ejercicio1 ejercicio2 ejercicio3 ejercicio4 ejercicio5     total
#> 1    Garcia          1          1          1          0          1 0.8333333
#> 2     Lopez          1          1          0          1          1 0.8333333
#> 3  Martinez          1          0          1          1          1 0.8333333
#> 4 Rodriguez          0          1          1          0          1 0.6666667
#> 5 Fernandez          1          1          1          0          0 0.5000000
#> 6  Gonzalez          1          0          1          1          1 0.8333333
#> 7     Perez          0          1          0          1          1 0.6666667
#> 8   Sanchez          1          1          0          1          0 0.5000000
```
