# Export grading results to an HTML report

Produces a self-contained HTML file with a colour-coded table (green =
pass, red = fail, amber = error/timeout, grey = missing), per-student
score column, and a pass-rate summary row.

## Usage

``` r
export_to_html(results, path, include_details = TRUE)
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- path:

  Output file path (e.g. `"report.html"`).

- include_details:

  If `TRUE`, append a per-test breakdown under each student (errors and
  timeouts include the message). Default `TRUE`.

## Value

`results`, invisibly.

## Examples

``` r
path <- tempfile(fileext = ".html")
export_to_html(example_results(), path)
file.exists(path)
#> [1] TRUE
```
