# Export grading results to a CSV file

Export grading results to a CSV file

## Usage

``` r
export_to_csv(results, path, format = c("wide", "long"))
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- path:

  Output file path (e.g. `"grades.csv"`).

- format:

  `"wide"` (default) writes one row per student with one logical column
  per exercise. `"long"` writes the per-test detail.

## Value

`results`, invisibly.

## Examples

``` r
path <- tempfile(fileext = ".csv")
export_to_csv(example_results(), path)
read.csv(path)
#>     student ejercicio1 ejercicio2 ejercicio3 ejercicio4 ejercicio5
#> 1    Garcia       TRUE       TRUE       TRUE      FALSE       TRUE
#> 2     Lopez       TRUE       TRUE      FALSE       TRUE       TRUE
#> 3  Martinez       TRUE      FALSE       TRUE       TRUE       TRUE
#> 4 Rodriguez      FALSE       TRUE       TRUE      FALSE       TRUE
#> 5 Fernandez       TRUE       TRUE       TRUE      FALSE      FALSE
#> 6  Gonzalez       TRUE      FALSE       TRUE       TRUE       TRUE
#> 7     Perez      FALSE       TRUE      FALSE       TRUE       TRUE
#> 8   Sanchez       TRUE       TRUE      FALSE       TRUE      FALSE
```
