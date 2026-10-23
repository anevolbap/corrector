# Corregir un ejercicio contra sus tests

Carga el archivo del estudiante y el archivo de tests que le corresponde
en un entorno aislado, corre cada función cuyo nombre empieza con
`test_<exercise>_` y devuelve el resultado de cada test como un objeto
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).

## Usage

``` r
grade_exercise(
  file,
  test_dir,
  timeout = 10,
  student = NA_character_,
  engine = c("callr", "inproc", "isolated"),
  allow_masking = character()
)
```

## Arguments

- file:

  Ruta al archivo del estudiante: un script de R (por ejemplo
  `"ejercicio1.R"`) o un documento R Markdown o Quarto (`.Rmd`, `.qmd`),
  del que se extraen los bloques de código R con
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html). El archivo
  de tests que le corresponde se busca sin distinguir mayúsculas de
  minúsculas. *English:* Path to the student's file: an R script (e.g.
  `"ejercicio1.R"`) or an R Markdown or Quarto document (`.Rmd`,
  `.qmd`), whose R chunks are extracted with
  [`knitr::purl()`](https://rdrr.io/pkg/knitr/man/knit.html). The
  matching test file is found ignoring case.

- test_dir:

  Carpeta que contiene los archivos de tests. *English:* Directory that
  contains the test files.

- timeout:

  Máximo de segundos permitido para cada función de test y para cargar
  el archivo del estudiante. Los tests que lo superan quedan registrados
  con estado `timeout`. Por defecto 10. Usá `Inf` para no poner límite.
  *English:* Maximum seconds allowed per test function, and for loading
  the student's file. Tests that exceed it are recorded with status
  `timeout`. Default 10. Use `Inf` for no limit.

- student:

  Nombre opcional del estudiante para mostrar. Por defecto `NA`.
  *English:* Optional student display name. Defaults to `NA`.

- engine:

  `"callr"` (por defecto) corre cada ejercicio en un subproceso nuevo de
  R con el paquete callr, con una carpeta de trabajo temporal. El
  timeout es un límite estricto de tiempo real, y las asignaciones con
  `<<-` o los archivos que escribe el estudiante no llegan a tu sesión
  ni a tu carpeta. `"inproc"` corre los tests en la sesión de R actual.
  Es más rápido, pero su timeout con
  [`setTimeLimit()`](https://rdrr.io/r/base/setTimeLimit.html) no corta
  todo tipo de bucle, y el código del estudiante puede ver y cambiar tu
  entorno global. `"isolated"` corre los tests en un subproceso y el
  código del estudiante en otro. Cada función del estudiante que llaman
  los tests corre en el proceso del estudiante y solo vuelve su
  resultado (datos simples). Así, trucos como
  [`attach()`](https://rdrr.io/r/base/attach.html), métodos S3 para
  comparaciones o funciones base reemplazadas no cambian la nota. Es más
  lento, y una función del estudiante no puede devolver una función ni
  un entorno. Usalo cuando te importa evitar trampas. *English:*
  `"callr"` (default) runs each exercise in a fresh R subprocess via the
  callr package, with a temporary working directory. The timeout is a
  hard wall-clock limit, and assignments with `<<-` or files the student
  writes do not reach your session or folder. `"inproc"` runs tests in
  the current R session. It is faster, but its
  [`setTimeLimit()`](https://rdrr.io/r/base/setTimeLimit.html) timeout
  does not interrupt every kind of loop, and student code can see and
  change your global environment. `"isolated"` runs the tests in one
  subprocess and the student code in another. Each student function the
  tests call runs in the student process and only its result (plain
  data) comes back, so tricks such as
  [`attach()`](https://rdrr.io/r/base/attach.html), S3 methods for
  comparisons or replaced base functions do not change the grade. It is
  slower, and a student function may not return a function or an
  environment. Use it when cheating matters.

- allow_masking:

  Vector de texto con nombres de funciones de R base y de los paquetes
  por defecto (stats, utils, methods, graphics, grDevices) que el
  estudiante puede redefinir, por ejemplo `"factorial"` cuando el
  ejercicio lo pide. Cualquier otro objeto del estudiante con uno de
  esos nombres no es visible para los tests, así que un estudiante no
  puede pasar los tests redefiniendo
  [`all()`](https://rdrr.io/r/base/all.html) o `==`. Los nombres
  ignorados aparecen en la columna `message`. *English:* Character
  vector of function names from base R and the default packages (stats,
  utils, methods, graphics, grDevices) that the student may redefine,
  e.g. `"factorial"` when the exercise asks for it. Any other student
  object with such a name is not visible to the tests, so a student
  cannot pass by redefining [`all()`](https://rdrr.io/r/base/all.html)
  or `==`. Ignored names are listed in the `message` column.

## Value

Un objeto
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
con una fila por test. Si el archivo del estudiante tiene errores de
sintaxis, una fila con `status = source_error`. Si no hay un archivo de
tests que le corresponda, una fila con `status = missing` y una
advertencia. *English:* A
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object with one row per test. If the student file fails to parse, one
row with `status = source_error`. If no matching test file is found, one
row with `status = missing` and a warning.

## Details

Un test pasa si devuelve `TRUE`. Los tests también pueden usar
expectativas de testthat (llamá a
[`library(testthat)`](https://testthat.r-lib.org) al principio del
archivo de tests): el test pasa cuando al menos una expectativa se
cumple y ninguna falla. Una expectativa que falla queda registrada como
`fail` con su mensaje.

## English

**Grade a single exercise file against its tests.** Sources the
student's file and the matching test file into an isolated environment,
runs every function whose name starts with `test_<exercise>_`, and
returns the per-test outcome as a
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object.

A test passes if it returns `TRUE`. Tests can also use testthat
expectations (call [`library(testthat)`](https://testthat.r-lib.org) at
the top of the test file): the test passes when at least one expectation
succeeds and none fails, and a failed expectation is recorded as `fail`
with its message.

## Examples

``` r
# The package ships test files for five sample exercises.
tests <- system.file("examples", package = "corrector")
file <- file.path(tempdir(), "ejercicio1.R")
writeLines(c(
  "ceros_cuadratica <- function(a, b, c) {",
  "  d <- sqrt(b^2 - 4 * a * c)",
  "  c((-b - d) / (2 * a), (-b + d) / (2 * a))",
  "}"
), file)
grade_exercise(file, tests, student = "Garcia")
#> <grade_results> 4 rows, 1 students, 1 exercises
#> Status:
#>   pass          3
#>   fail          1
```
