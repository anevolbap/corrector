# Resultados de ejemplo

Un objeto
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
chico y falso, con 8 estudiantes y 5 ejercicios. Sirve para probar
[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
[`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
y las funciones de exportación sin necesitar entregas reales.

## Usage

``` r
example_results()
```

## Value

Un objeto
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md).
*English:* A
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object.

## English

**Sample grading results.** A small fake
[grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
object with 8 students and 5 exercises, useful for trying out
[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
[`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md),
and the export functions without needing real student submissions.

## Examples

``` r
results <- example_results()
grade_report(results)
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
plot_report(results, ask = FALSE)


```
