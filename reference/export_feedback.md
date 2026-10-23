# Escribir un archivo de devolución por estudiante

Escribe `<student>.md` en `dir` para cada estudiante: el puntaje total,
el puntaje de cada ejercicio y el estado de cada test, con el mensaje de
error cuando lo hay. Usala para mandarle a cada estudiante sus
resultados.

## Usage

``` r
export_feedback(
  results,
  dir,
  scoring = c("partial", "all"),
  weights = NULL,
  lang = default_lang()
)
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
  *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object.

- dir:

  Carpeta donde escribir. Se crea si hace falta. *English:* Folder to
  write into. Created if needed.

- scoring, weights:

  Se pasan a
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).
  *English:* Passed to
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- lang:

  Idioma de los archivos: `"es"` o `"en"`. Por defecto sigue el idioma
  de la computadora (`LANGUAGE` o la configuración regional): inglés si
  es inglés, castellano en cualquier otro caso. *English:* Language of
  the files: `"es"` or `"en"`. By default it follows the computer's
  language (`LANGUAGE` or the locale): English if that is English,
  Spanish otherwise.

## Value

Las rutas de los archivos escritos, con el nombre de cada estudiante, de
forma invisible. *English:* The paths of the written files, named by
student, invisibly.

## English

**Write one feedback file per student.** Writes `<student>.md` into
`dir` for every student: the total score, the score of each exercise,
and the status of each test, with the error message when there is one.
Use it to send each student their results.

## Examples

``` r
dir <- file.path(tempdir(), "feedback")
paths <- export_feedback(example_results(), dir)
writeLines(readLines(paths[[1]]))
#> # Garcia
#> 
#> Nota total: 80%
#> 
#> ## ejercicio1: 100%
#> 
#> - `test_ejercicio1_case1`: aprobado
#> 
#> ## ejercicio2: 100%
#> 
#> - `test_ejercicio2_case1`: aprobado
#> 
#> ## ejercicio3: 100%
#> 
#> - `test_ejercicio3_case1`: aprobado
#> 
#> ## ejercicio4: 0%
#> 
#> - `test_ejercicio4_case1`: no aprobado
#> 
#> ## ejercicio5: 100%
#> 
#> - `test_ejercicio5_case1`: aprobado
#> 
```
