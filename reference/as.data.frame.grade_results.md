# Convertir los resultados de la corrección en un data frame

Convertir los resultados de la corrección en un data frame

## Usage

``` r
# S3 method for class 'grade_results'
as.data.frame(
  x,
  row.names = NULL,
  optional = FALSE,
  format = c("long", "wide"),
  ...
)
```

## Arguments

- x:

  Un objeto `grade_results`. *English:* A `grade_results` object.

- row.names:

  Se ignora. *English:* Ignored.

- optional:

  Se ignora. *English:* Ignored.

- format:

  `"long"` devuelve el data frame en formato largo que guarda el objeto.
  `"wide"` devuelve la vista anterior: una fila por estudiante, una
  columna lógica por ejercicio (`TRUE` si y solo si pasaron todos los
  tests; `NA` para `missing` o `source_error`). *English:* `"long"`
  returns the underlying long-format data frame. `"wide"` returns the
  legacy view: one row per student, one logical column per exercise
  (`TRUE` iff all tests passed; `NA` for `missing` or `source_error`).

- ...:

  Se ignora. *English:* Ignored.

## Value

Un data frame común. *English:* A plain data frame.

## English

**Convert grading results to a data frame.**

## Examples

``` r
results <- example_results()
head(as.data.frame(results))
#>     student   exercise                  test status message duration
#> 1    Garcia ejercicio1 test_ejercicio1_case1   pass    <NA>        0
#> 2     Lopez ejercicio1 test_ejercicio1_case1   pass    <NA>        0
#> 3  Martinez ejercicio1 test_ejercicio1_case1   pass    <NA>        0
#> 4 Rodriguez ejercicio1 test_ejercicio1_case1   fail    <NA>        0
#> 5 Fernandez ejercicio1 test_ejercicio1_case1   pass    <NA>        0
#> 6  Gonzalez ejercicio1 test_ejercicio1_case1   pass    <NA>        0
as.data.frame(results, format = "wide")
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
