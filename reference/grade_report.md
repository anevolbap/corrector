# Resumen de los resultados de la corrección

Calcula el porcentaje de aprobación por ejercicio y el puntaje por
estudiante, y cuenta los errores, los timeouts y las entregas que
faltan. El objeto que devuelve tiene un método
[`print()`](https://rdrr.io/r/base/print.html) que muestra un resumen
legible en la consola.

## Usage

``` r
grade_report(results, scoring = c("all", "partial"), weights = NULL)
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  que devuelve
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  o
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).
  *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object returned by
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  or
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md).

- scoring:

  `"all"` (por defecto): un ejercicio cuenta como aprobado solo si pasan
  todos sus tests. `"partial"`: su puntaje es la fracción de tests que
  pasan. Ver
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).
  *English:* `"all"` (default): an exercise counts as passed only if
  every test passes. `"partial"`: it scores the fraction of tests that
  pass. See
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- weights:

  Vector numérico con nombres, opcional, con los pesos de tests o
  ejercicios. Ver
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).
  *English:* Optional named numeric vector of test or exercise weights.
  See
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

## Value

Un objeto `grade_report` (una lista) con estos componentes:

- `pass_rate_by_exercise`:

  Vector numérico con nombres (0-1). Puntaje medio del ejercicio entre
  todos los estudiantes.

- `score_by_student`:

  Vector numérico con nombres (0-1). El `total` del estudiante en
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- `overall_mean`:

  Numérico, un solo valor (0-1).

- `issue_counts`:

  Vector de enteros con nombres, con la cantidad de filas `error`,
  `timeout`, `missing` y `source_error`.

- `flagged`:

  Vector de texto con los estudiantes que tienen una nota
  `suspicious code:` o `tampering:` en la columna `message` (ver
  [`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md)).

En `pass_rate_by_exercise` y `score_by_student`, un ejercicio `missing`
o con un `source_error` cuenta como 0. *English:* A `grade_report`
object (a list) with components:

- `pass_rate_by_exercise`:

  Named numeric vector (0-1). Mean exercise score across students.

- `score_by_student`:

  Named numeric vector (0-1). The student's `total` from
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md).

- `overall_mean`:

  Scalar numeric (0-1).

- `issue_counts`:

  Named integer vector with counts of `error`, `timeout`, `missing`, and
  `source_error` rows.

- `flagged`:

  Character vector of students with suspicious code or tampering noted
  in the `message` column (see
  [`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md)).

In `pass_rate_by_exercise` and `score_by_student`, a `missing` exercise
or one with a `source_error` counts as 0.

## English

**Summarise grading results.** Computes pass rate per exercise and score
per student, plus counts of errors, timeouts, and missing submissions.
The returned object has a [`print()`](https://rdrr.io/r/base/print.html)
method that renders a readable console summary.

## Examples

``` r
report <- grade_report(example_results())
report
#> === Grade Report ===
#> 
#> Pass rate by exercise:
#>   ejercicio1                75%
#>   ejercicio2                75%
#>   ejercicio3                62%
#>   ejercicio4                62%
#>   ejercicio5                75%
#> 
#> Overall mean score: 70%
#> 
#> Score by student (descending):
#>   Garcia               ################     80%
#>   Lopez                ################     80%
#>   Martinez             ################     80%
#>   Gonzalez             ################     80%
#>   Rodriguez            ############         60%
#>   Fernandez            ############         60%
#>   Perez                ############         60%
#>   Sanchez              ############         60%
report$score_by_student
#>    Garcia     Lopez  Martinez Rodriguez Fernandez  Gonzalez     Perez   Sanchez 
#>       0.8       0.8       0.8       0.6       0.6       0.8       0.6       0.6 
```
