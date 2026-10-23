# Exportar los resultados a un archivo CSV

Las celdas de texto que empiezan con `=`, `+`, `-` o `@` reciben un `'`
adelante, así la planilla no las corre como fórmulas (los mensajes de
error vienen del código del estudiante).

## Usage

``` r
export_to_csv(results, path, format = c("wide", "long"))
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
  *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- path:

  Ruta del archivo de salida (por ejemplo `"grades.csv"`). *English:*
  Output file path (e.g. `"grades.csv"`).

- format:

  `"wide"` (por defecto) escribe una fila por estudiante, con una
  columna lógica por ejercicio. `"long"` escribe el detalle por test.
  *English:* `"wide"` (default) writes one row per student with one
  logical column per exercise. `"long"` writes the per-test detail.

## Value

`results`, de forma invisible. *English:* `results`, invisibly.

## English

**Export grading results to a CSV file.** Text cells that start with
`=`, `+`, `-` or `@` get a leading `'`, so a spreadsheet app does not
run them as formulas (error messages come from student code).

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
