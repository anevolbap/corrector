# Buscar código sospechoso en el archivo de un estudiante

Busca llamadas que cambian cómo se comporta otro código
([`attach()`](https://rdrr.io/r/base/attach.html),
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
[`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
[`trace()`](https://rdrr.io/r/base/trace.html), `setMethod()` y
similares), escrituras en el entorno global o en el entorno base, código
armado a partir de texto con `parse(text = )`, y cambios en el cuerpo o
el entorno de una función.
[`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
la corre sobre cada entrega y anota lo que encuentra en la columna
`message` como `suspicious code: ...`. El código solo se lee, nunca se
ejecuta.

## Usage

``` r
scan_code(path)
```

## Arguments

- path:

  Ruta a un archivo de R. *English:* Path to an R file.

## Value

Vector de texto con lo que encuentra, por ejemplo
`"attach() at line 3"`; vacío cuando no encuentra nada o cuando el
archivo no se puede parsear. *English:* Character vector of findings
such as `"attach() at line 3"`; empty when nothing is found or the file
does not parse.

## English

**Find suspicious code in a student file.** Looks for calls that change
how other code behaves
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

## Examples

``` r
file <- tempfile(fileext = ".R")
writeLines(c("f <- function(x) x", 'attach(list(isTRUE = function(x) TRUE))'), file)
scan_code(file)
#> [1] "attach() at line 2"
```
