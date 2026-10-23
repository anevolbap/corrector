# Exportar los resultados a un informe HTML

Genera un archivo HTML autocontenido con una tabla por colores (verde =
pass, rojo = fail, ámbar = error/timeout, gris = missing), una columna
con el puntaje de cada estudiante y una fila final con el porcentaje de
aprobación.

## Usage

``` r
export_to_html(
  results,
  path,
  include_details = TRUE,
  scoring = c("all", "partial"),
  weights = NULL
)
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
  *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- path:

  Ruta del archivo de salida (por ejemplo `"report.html"`). *English:*
  Output file path (e.g. `"report.html"`).

- include_details:

  Si es `TRUE`, agrega el detalle por test debajo de cada estudiante
  (los errores y timeouts incluyen el mensaje). Por defecto `TRUE`.
  *English:* If `TRUE`, append a per-test breakdown under each student
  (errors and timeouts include the message). Default `TRUE`.

- scoring, weights:

  Cómo se calculan la columna de puntaje y la fila de porcentaje de
  aprobación. Mirá
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).
  *English:* How the score column and pass-rate row are computed. See
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).

## Value

`results`, de forma invisible. *English:* `results`, invisibly.

## English

**Export grading results to an HTML report.** Produces a self-contained
HTML file with a colour-coded table (green = pass, red = fail, amber =
error/timeout, grey = missing), per-student score column, and a
pass-rate summary row.

## Examples

``` r
path <- tempfile(fileext = ".html")
export_to_html(example_results(), path)
file.exists(path)
#> [1] TRUE
```
