# Find suspicious code in a student file

Looks for calls that change how other code behaves
([`attach()`](https://rdrr.io/r/base/attach.html),
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
[`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
[`trace()`](https://rdrr.io/r/base/trace.html), `setMethod()` and
similar), writes into the global or base environment, code built from
strings with `parse(text = )`, and replacement of a function's body or
environment.
[`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
runs it on every submission and puts the findings in the `message`
column as "suspicious code: ...". The code is only read, never run.

## Usage

``` r
scan_code(path)
```

## Arguments

- path:

  Path to an R file.

## Value

Character vector of findings such as `"attach() at line 3"`; empty when
nothing is found or the file does not parse.

## Examples

``` r
file <- tempfile(fileext = ".R")
writeLines(c("f <- function(x) x", 'attach(list(isTRUE = function(x) TRUE))'), file)
scan_code(file)
#> [1] "attach() at line 2"
```
