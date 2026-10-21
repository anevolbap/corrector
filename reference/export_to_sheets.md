# Export grading results to a Google Sheet

Writes results to an existing Google Sheet, replacing its contents.
Requires the googlesheets4 package and prior authentication; call
[`googlesheets4::gs4_auth()`](https://googlesheets4.tidyverse.org/reference/gs4_auth.html)
once per session before using this function.

## Usage

``` r
export_to_sheets(results, sheet_url, sheet = 1, format = c("wide", "long"))
```

## Arguments

- results:

  A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- sheet_url:

  URL of the target Google Sheet.

- sheet:

  Name or index of the worksheet tab (default: first sheet).

- format:

  `"wide"` (default) or `"long"`.

## Value

`results`, invisibly.

## Examples

``` r
if (FALSE) { # \dontrun{
googlesheets4::gs4_auth()
export_to_sheets(example_results(),
                 "https://docs.google.com/spreadsheets/d/<sheet-id>")
} # }
```
