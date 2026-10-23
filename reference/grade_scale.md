# Pasar puntajes a una escala de notas

Convierte puntajes entre 0 y 1 (por ejemplo `student_scores()$total`) en
notas. La escala es lineal en dos tramos: de 0 a `pass_at` la nota va de
`min` a `pass`, y de `pass_at` a 1 va de `pass` a `max`. Con los valores
por defecto es una escala de 1 a 10 donde el 60% es un 4. El redondeo
nunca sube a la nota de aprobación un puntaje menor que `pass_at`.

## Usage

``` r
grade_scale(x, min = 1, max = 10, pass = 4, pass_at = 0.6, digits = 0)
```

## Arguments

- x:

  Vector numérico de puntajes entre 0 y 1. Los `NA` se mantienen.
  *English:* Numeric vector of scores between 0 and 1. `NA` stays `NA`.

- min, max:

  Nota más baja y más alta de la escala. *English:* Lowest and highest
  grade on the scale.

- pass:

  Nota de aprobación. *English:* Pass mark.

- pass_at:

  Puntaje (entre 0 y 1) que corresponde a la nota de aprobación.
  *English:* Score (between 0 and 1) that earns the pass mark.

- digits:

  Cantidad de decimales de la nota. *English:* Number of decimal places
  in the grade.

## Value

Vector numérico de notas, del mismo largo que `x`. *English:* Numeric
vector of grades, the same length as `x`.

## English

**Map scores to a grade scale.** Turns scores between 0 and 1 (for
example `student_scores()$total`) into grades. The scale is linear in
two parts: from 0 to `pass_at` the grade goes from `min` to `pass`, and
from `pass_at` to 1 it goes from `pass` to `max`. With the defaults it
is a 1-10 scale where 60% is a 4. Rounding never lifts a score below
`pass_at` to the pass mark.

## Examples

``` r
grade_scale(c(0, 0.5, 0.6, 0.85, 1))
#> [1]  1  3  4  8 10
notas <- student_scores(example_results())
notas$nota <- grade_scale(notas$total)
notas[, c("student", "total", "nota")]
#>     student total nota
#> 1    Garcia   0.8    7
#> 2     Lopez   0.8    7
#> 3  Martinez   0.8    7
#> 4 Rodriguez   0.6    4
#> 5 Fernandez   0.6    4
#> 6  Gonzalez   0.8    7
#> 7     Perez   0.6    4
#> 8   Sanchez   0.6    4
```
