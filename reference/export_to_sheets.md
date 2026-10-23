# Exportar los resultados a una planilla de Google Sheets

Escribe los resultados en una planilla de Google Sheets que ya existe y
reemplaza su contenido. Las celdas de texto que podrían correr como
fórmulas reciben un `'` adelante, como en
[`export_to_csv()`](https://anevolbap.github.io/corrector/reference/export_to_csv.md).
Necesita el paquete googlesheets4 y una autenticación previa: corré
[`googlesheets4::gs4_auth()`](https://googlesheets4.tidyverse.org/reference/gs4_auth.html)
una vez por sesión antes de usar esta función.

## Usage

``` r
export_to_sheets(results, sheet_url, sheet = 1, format = c("wide", "long"))
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
  *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- sheet_url:

  URL de la planilla de Google Sheets de destino. *English:* URL of the
  target Google Sheet.

- sheet:

  Nombre o número de la pestaña (por defecto: la primera). *English:*
  Name or index of the worksheet tab (default: first sheet).

- format:

  `"wide"` (por defecto) o `"long"`. *English:* `"wide"` (default) or
  `"long"`.

## Value

`results`, de forma invisible. *English:* `results`, invisibly.

## English

**Export grading results to a Google Sheet.** Writes results to an
existing Google Sheet, replacing its contents. Text cells that could run
as formulas get a leading `'`, as in
[`export_to_csv()`](https://anevolbap.github.io/corrector/reference/export_to_csv.md).
Requires the googlesheets4 package and prior authentication; call
[`googlesheets4::gs4_auth()`](https://googlesheets4.tidyverse.org/reference/gs4_auth.html)
once per session before using this function.

## Examples

``` r
if (FALSE) { # \dontrun{
googlesheets4::gs4_auth()
export_to_sheets(example_results(),
                 "https://docs.google.com/spreadsheets/d/<sheet-id>")
} # }
```
