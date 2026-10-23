# Extractor por defecto del nombre del estudiante

Divide el nombre de la carpeta en los guiones bajos, toma la primera
parte, la pasa a minúsculas y después le aplica
[`tools::toTitleCase()`](https://rdrr.io/r/tools/toTitleCase.html).
Ejemplos: `"garcia_juan_12345"` da `"Garcia"`; `"lopez"` da `"Lopez"`.

## Usage

``` r
default_student_name(folder)
```

## Arguments

- folder:

  Texto. Nombre de la carpeta de la entrega. *English:* Character.
  Submission folder name.

## Value

Texto. Nombre para mostrar. *English:* Character. Display name.

## English

**Default student-name extractor.** Splits the folder name on
underscores, takes the first segment, lower-cases it, then applies
[`tools::toTitleCase()`](https://rdrr.io/r/tools/toTitleCase.html).
Examples: `"garcia_juan_12345"` becomes `"Garcia"`; `"lopez"` becomes
`"Lopez"`.

## Examples

``` r
default_student_name("garcia_juan_12345")
#> [1] "Garcia"
default_student_name("LOPEZ")
#> [1] "Lopez"
```
