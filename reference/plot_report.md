# Plot a visual summary of grading results

Produces three plots in sequence:

1.  Student scores ranked (horizontal bar chart).

2.  Pass rate per exercise (bar chart).

3.  Pass/fail heatmap (students x exercises).

## Usage

``` r
plot_report(
  results,
  ask = interactive(),
  backend = c("base", "ggplot2"),
  scoring = c("all", "partial"),
  weights = NULL
)
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- ask:

  If `TRUE` (default in interactive sessions), pause between plots. Pass
  `FALSE` when rendering to a file device (PDF, PNG, etc.).

- backend:

  `"base"` (default) uses base graphics, no extra dependencies.
  `"ggplot2"` uses ggplot2 when installed and falls back to base R with
  a warning otherwise.

- scoring, weights:

  How the two bar charts score students and exercises. See
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).
  The heatmap always shows pass/fail.

## Value

`results`, invisibly.

## Examples

``` r
plot_report(example_results(), ask = FALSE)


```
