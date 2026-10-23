# Graficar un resumen visual de los resultados

Genera tres gráficos, uno después del otro:

1.  Puntajes de los estudiantes ordenados (gráfico de barras
    horizontales).

2.  Porcentaje de aprobación por ejercicio (gráfico de barras).

3.  Mapa de calor de pass/fail (estudiantes x ejercicios).

## Usage

``` r
plot_report(
  results,
  ask = interactive(),
  backend = c("base", "ggplot2"),
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

- ask:

  Si es `TRUE` (por defecto en sesiones interactivas), hace una pausa
  entre gráficos. Pasá `FALSE` cuando dibujás en un dispositivo de
  archivo (PDF, PNG, etc.). *English:* If `TRUE` (default in interactive
  sessions), pause between plots. Pass `FALSE` when rendering to a file
  device (PDF, PNG, etc.).

- backend:

  `"base"` (por defecto) usa los gráficos base de R, sin dependencias
  extra. `"ggplot2"` usa ggplot2 si está instalado. Si no, vuelve a R
  base con una advertencia. *English:* `"base"` (default) uses base
  graphics, no extra dependencies. `"ggplot2"` uses ggplot2 when
  installed and falls back to base R with a warning otherwise.

- scoring, weights:

  Cómo los dos gráficos de barras calculan el puntaje de estudiantes y
  ejercicios. Mirá
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).
  El mapa de calor siempre muestra pass/fail. *English:* How the two bar
  charts score students and exercises. See
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).
  The heatmap always shows pass/fail.

## Value

`results`, de forma invisible. *English:* `results`, invisibly.

## English

**Plot a visual summary of grading results.** Produces three plots in
sequence:

1.  Student scores ranked (horizontal bar chart).

2.  Pass rate per exercise (bar chart).

3.  Pass/fail heatmap (students x exercises).

## Examples

``` r
plot_report(example_results(), ask = FALSE)


```
