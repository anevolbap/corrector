# Corregir todas las entregas de una carpeta o archivo .zip

Espera una subcarpeta por estudiante dentro de `submissions_path`. Cada
estudiante se corrige en cada ejercicio que tiene un archivo de tests en
`test_dir`. Un estudiante que no entrega un ejercicio recibe una fila
`missing`. El archivo del estudiante se busca sin distinguir mayúsculas
de minúsculas (`Ejercicio1.R` cuenta como `ejercicio1`), y se aceptan
archivos `.Rmd` o `.qmd` cuando no hay un archivo `.R`.

## Usage

``` r
grade_submissions(
  submissions_path,
  test_dir,
  timeout = 10,
  engine = c("callr", "inproc", "isolated", "container"),
  student_name_fn = default_student_name,
  allow_masking = character(),
  workers = 1L,
  layout = c("folders", "moodle")
)
```

## Arguments

- submissions_path:

  Ruta a una carpeta o archivo `.zip` con las entregas. *English:* Path
  to a directory or `.zip` archive of submissions.

- test_dir:

  Carpeta que contiene los archivos de tests. *English:* Directory that
  contains the test files.

- timeout:

  Máximo de segundos permitido para cada función de test. Por
  defecto 10. *English:* Maximum seconds allowed per test function.
  Default 10.

- engine:

  `"callr"` (por defecto), `"inproc"`, `"isolated"` o `"container"`.
  Mirá
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).
  *English:* `"callr"` (default), `"inproc"`, `"isolated"` or
  `"container"`. See
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- student_name_fn:

  Función que se aplica al nombre de cada carpeta de estudiante para
  obtener el nombre para mostrar. Por defecto toma la primera parte
  separada por guiones bajos y la pasa a formato título. Las carpetas
  que dan el mismo nombre conservan el nombre de la carpeta, con una
  advertencia. *English:* Function applied to each student folder name
  to produce the display name. Defaults to taking the first
  underscore-separated token and applying title case. Folders that map
  to the same name keep their folder name, with a warning.

- allow_masking:

  Nombres de funciones base que los estudiantes pueden redefinir. Mirá
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).
  *English:* Base function names students may redefine. See
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- workers:

  Cantidad de subprocesos de callr que corren al mismo tiempo. Por
  defecto 1. Valores mayores que 1 aceleran la corrección de cursos
  grandes; un valor cercano a
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)
  es un buen límite superior. El motor `"inproc"` lo ignora. *English:*
  Number of callr subprocesses to run at the same time. Default 1.
  Values above 1 speed up large classes; a value near
  [`parallel::detectCores()`](https://rdrr.io/r/parallel/detectCores.html)
  is a good upper bound. Ignored by the `"inproc"` engine.

- layout:

  `"folders"` (por defecto): una carpeta por estudiante. `"moodle"`: el
  archivo .zip o la carpeta de "Descargar todas las entregas" de Moodle,
  con o sin "Descargar entregas en carpetas". Solo se corrigen las
  entregas de archivos, y `student_name_fn` pasa a ser por defecto
  [`moodle_student_name()`](https://anevolbap.github.io/corrector/reference/moodle_student_name.md).
  *English:* `"folders"` (default): one folder per student. `"moodle"`:
  the zip or folder from Moodle's "Download all submissions", with or
  without "Download submissions in folders". Only file submissions are
  graded, and `student_name_fn` defaults to
  [`moodle_student_name()`](https://anevolbap.github.io/corrector/reference/moodle_student_name.md).

## Value

Un objeto
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
*English:* A
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object.

## Details

Si `submissions_path` termina en `.zip`, primero se extrae en una
subcarpeta de [`tempdir()`](https://rdrr.io/r/base/tempfile.html). Se
ignoran los archivos sueltos, las carpetas ocultas y `__MACOSX`. Si la
ruta tiene una sola carpeta sin archivos `.R`, `.Rmd` ni `.qmd` pero con
subcarpetas, esas subcarpetas se toman como los estudiantes.

## English

**Grade all student submissions in a directory or zip archive.** Expects
one sub-folder per student inside `submissions_path`. Every student is
graded on every exercise that has a test file in `test_dir`; a student
who omits an exercise gets a `missing` row. The student's file is
matched ignoring case (`Ejercicio1.R` counts as `ejercicio1`), and
`.Rmd` or `.qmd` files are accepted when there is no `.R` file.

If `submissions_path` ends in `.zip` it is extracted into a
[`tempdir()`](https://rdrr.io/r/base/tempfile.html) subfolder first.
Loose files, hidden folders and `__MACOSX` are ignored. If the path
holds a single folder with no `.R`, `.Rmd` or `.qmd` files but with
sub-folders, those sub-folders are taken as the students.

## Examples

``` r
# One folder per student, one test file per exercise.
root <- file.path(tempdir(), "entregas")
dir.create(file.path(root, "garcia_juan"), recursive = TRUE)
dir.create(file.path(root, "lopez_maria"), recursive = TRUE)
writeLines("ceros_cuadratica <- function(a, b, c) c(-1, 1)",
           file.path(root, "garcia_juan", "ejercicio1.R"))
writeLines("ceros_cuadratica <- function(a, b, c) 0",
           file.path(root, "lopez_maria", "ejercicio1.R"))
tests <- file.path(tempdir(), "tests")
dir.create(tests)
file.copy(system.file("examples", "test_ejercicio1.R", package = "corrector"),
          tests)
#> [1] TRUE
results <- grade_submissions(root, tests)
results
#> <grade_results> 8 rows, 2 students, 1 exercises
#> Status:
#>   pass          4
#>   fail          4
as.data.frame(results, format = "wide")
#>   student ejercicio1
#> 1  Garcia      FALSE
#> 2   Lopez      FALSE
```
