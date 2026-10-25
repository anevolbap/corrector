# Corregir entregas de principio a fin

*[English
version](https://anevolbap.github.io/corrector/articles/grading-pipeline.md)*

Este artículo recorre una corrección completa: escribir los tests,
juntar las entregas, corregir, resumir y exportar.

## Estructura de carpetas

El corrector espera una carpeta por estudiante dentro de una carpeta de
entregas, y una carpeta con los archivos de tests. Los nombres siguen
una convención simple:

    entregas/
      garcia_juan/
        ejercicio1.R
        ejercicio2.R
      lopez_maria/
        ejercicio1.R
        ejercicio2.R

    tests/
      test_ejercicio1.R
      test_ejercicio2.R

Un archivo de tests tiene una o más funciones con el nombre
`test_<ejercicio>_<caso>` que devuelven `TRUE` o `FALSE`.

``` r

# tests/test_ejercicio1.R
test_ejercicio1_raices <- function() {
  all(ceros_cuadratica(1, 0, -1) == c(-1, 1))
}
test_ejercicio1_numerico <- function() {
  is.numeric(ceros_cuadratica(1, 0, -1))
}
```

## Correr el corrector

``` r

library(corrector)

resultados <- grade_submissions("entregas/", test_dir = "tests/")
```

`resultados` es un objeto `grade_results`: un data frame en formato
largo con una fila por test y las columnas `student`, `exercise`,
`test`, `status`, `message` y `duration`. `status` es uno de `pass`,
`fail`, `error`, `timeout`, `missing` o `source_error`. Así se distingue
un test que devolvió `FALSE` de uno que dio error, que agotó el tiempo,
o de un archivo que no se entregó o no se pudo cargar.

``` r

head(as.data.frame(resultados, format = "long"))
```

Para la vista ancha (una columna lógica por ejercicio) usá
`as.data.frame(resultados, format = "wide")`. Ahí `NA` indica que el
ejercicio no se entregó o que el archivo no se pudo cargar.

Mientras escribís los tests, probalos sobre un solo archivo:

``` r

grade_exercise("entregas/garcia_juan/ejercicio1.R", test_dir = "tests/")
```

## Probar sin entregas reales

[`example_results()`](https://anevolbap.github.io/corrector/reference/example_results.md)
devuelve resultados ficticios (8 estudiantes, 5 ejercicios) para probar
los resúmenes, los gráficos y las exportaciones. El paquete también trae
archivos de tests para cinco ejercicios de ejemplo: raíces de una
ecuación cuadrática, búsqueda de palabras, ordenamiento, simulación y
transformación de data frames.

``` r

grade_report(example_results())
list.files(system.file("examples", package = "corrector"))
```

## Resumir

[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
resume los resultados: porcentaje de aprobación por ejercicio, nota por
estudiante y cantidad de errores, timeouts y entregas faltantes. Un
ejercicio no entregado cuenta como 0.

``` r

grade_report(resultados)
```

[`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
dibuja tres gráficos: la nota de cada estudiante, el porcentaje de
aprobación por ejercicio y un mapa de calor con los resultados. Pasá
`backend = "ggplot2"` para usar ggplot2, si está instalado. Para
guardarlos en un PDF:

``` r

pdf("informe.pdf", width = 8, height = 5)
plot_report(resultados, ask = FALSE)
dev.off()
```

## Exportar

``` r

export_to_csv(resultados, "notas.csv")               # vista ancha por defecto
export_to_csv(resultados, "notas-largo.csv", format = "long")
export_to_html(resultados, "informe.html")
```

El informe HTML pinta cada celda según el resultado e incluye el detalle
de cada test por estudiante. Para escribir en una planilla de Google
(necesita el paquete googlesheets4):

``` r

googlesheets4::gs4_auth()
export_to_sheets(resultados, "https://docs.google.com/spreadsheets/d/...")
```

## Puntaje parcial, pesos y devoluciones

[`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md)
le da a cada ejercicio la fracción de tests que pasan, con pesos
opcionales por test o por ejercicio, y una nota `total` donde un
ejercicio no entregado cuenta como 0.
`grade_report(scoring = "partial")` usa las mismas reglas.
[`grade_scale()`](https://anevolbap.github.io/corrector/reference/grade_scale.md)
pasa ese puntaje a una nota (de 1 a 10 y con el 60% como 4, por
defecto).
[`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md)
escribe un archivo Markdown por estudiante, en castellano o en inglés
según `lang`.

``` r

notas <- student_scores(resultados, weights = c(ejercicio2 = 2))
notas$nota <- grade_scale(notas$total)
export_feedback(resultados, "devoluciones/", lang = "es")
```

## Entregas parecidas

[`compare_submissions()`](https://anevolbap.github.io/corrector/reference/compare_submissions.md)
lista, para cada ejercicio, los pares de estudiantes con archivos muy
parecidos, aunque hayan cambiado nombres de variables, espacios o
comentarios. Una similitud alta no prueba una copia; sirve para elegir
qué mirar a mano.

``` r

compare_submissions("entregas/", min_similarity = 0.8)
```

## testthat, R Markdown y Quarto

Los tests pueden usar expectativas de testthat (con
[`library(testthat)`](https://testthat.r-lib.org) al principio del
archivo de tests). Los estudiantes pueden entregar archivos `.R`, `.Rmd`
o `.qmd`, y los nombres se comparan sin importar mayúsculas.

## Tiempo límite y código no confiable

El motor por defecto, `"callr"`, corre cada ejercicio en un subproceso
de R nuevo, con una carpeta de trabajo temporal. Cada test tiene
`timeout` segundos (10 por defecto), y la carga del archivo del
estudiante también. Si un test no responde al límite (por ejemplo dentro
de [`Sys.sleep()`](https://rdrr.io/r/base/Sys.sleep.html)), el
subproceso se corta cuando el ejercicio completo pasa `timeout` ×
cantidad de tests + 5 segundos; los tests que ya terminaron conservan su
resultado. Usá `timeout = Inf` para no poner límite.

``` r

resultados <- grade_submissions("entregas/", test_dir = "tests/", timeout = 30)
```

`engine = "inproc"` corre los tests en la sesión actual de R. Es más
rápido, pero
[`setTimeLimit()`](https://rdrr.io/r/base/setTimeLimit.html) no
interrumpe todos los bucles y el código del estudiante puede modificar
tu entorno global.

Para cursos grandes, `workers` corre varios subprocesos a la vez:

``` r

resultados <- grade_submissions("entregas/", test_dir = "tests/", workers = 4)
```

corrector no es un sandbox. El motor `callr` protege tu sesión de R, no
tu computadora: el código del estudiante puede leer y escribir cualquier
archivo al que tenga acceso tu usuario, usar la red o ejecutar comandos
del sistema. Si no confiás en quien escribió el código, corré el
corrector dentro de un contenedor o una máquina virtual sin tus
credenciales. Los motores `callr` e `inproc` bloquean las trampas
comunes y anotan las demás; `engine = "isolated"` deja el código del
estudiante fuera del proceso que corre los tests. Mirá
[`vignette("evaluacion-anti-trampas")`](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.md).

## Nombres de los estudiantes

Por defecto el nombre es el primer segmento del nombre de la carpeta,
separado por guiones bajos, con mayúscula inicial (`garcia_juan_12345`
queda como `Garcia`). Pasá `student_name_fn` para cambiarlo:

``` r

resultados <- grade_submissions(
  "entregas/", test_dir = "tests/",
  student_name_fn = function(carpeta) {
    sub("_.*$", "", carpeta)
  }
)
```

## Moodle

`layout = "moodle"` lee el `.zip` de “Descargar todas las entregas” de
Moodle, con o sin “Descargar entregas en carpetas”:

``` r

resultados <- grade_submissions("tarea1.zip", test_dir = "tests/",
                                layout = "moodle")
```

Para devolver las notas,
[`export_moodle_feedback()`](https://anevolbap.github.io/corrector/reference/export_moodle_feedback.md)
arma un `.zip` con un archivo de devolución dentro de la carpeta de
Moodle de cada estudiante. En la página de entregas de la tarea, usá la
opción para subir varios archivos de retroalimentación en un zip (en
inglés, *Upload multiple feedback files in a zip*); la tarea tiene que
tener activada la retroalimentación con archivos.

``` r

export_moodle_feedback(resultados, "devoluciones-tarea1.zip")
```
