# Default student-name extractor

Splits the folder name on underscores, takes the first segment,
lower-cases it, then applies
[`tools::toTitleCase()`](https://rdrr.io/r/tools/toTitleCase.html).
Examples: `"garcia_juan_12345"` becomes `"Garcia"`; `"lopez"` becomes
`"Lopez"`.

## Usage

``` r
default_student_name(folder)
```

## Arguments

- folder:

  Character. Submission folder name.

## Value

Character. Display name.

## Examples

``` r
default_student_name("garcia_juan_12345")
#> [1] "Garcia"
default_student_name("LOPEZ")
#> [1] "Lopez"
```
