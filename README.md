# corrector

[English version](https://github.com/anevolbap/corrector/blob/main/README.en.md)

Paquete de R para corregir ejercicios de programación en R. Cada estudiante
entrega un archivo por ejercicio (`.R`, `.Rmd` o `.qmd`), el docente escribe
los tests, y corrector corrige el curso entero de una vez, en tu computadora.
Lee las entregas de una tarea de Moodle y prepara las devoluciones para
subirlas de vuelta.

Guías: [Corregir entregas de principio a fin](https://anevolbap.github.io/corrector/articles/corregir-entregas.html) ·
[Corregir sin que te hagan trampa](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.html) ·
[Referencia de funciones](https://anevolbap.github.io/corrector/reference/)

## Instalación

```r
# install.packages("remotes")
remotes::install_github("anevolbap/corrector")
```

## Ejemplo de principio a fin

```r
library(corrector)

# --- 1. Crear carpetas de entregas de ejemplo ---
dir.create("entregas/garcia", recursive = TRUE)
dir.create("entregas/lopez",  recursive = TRUE)
dir.create("tests")

writeLines(
  'ceros_cuadratica <- function(a, b, c) {
     d <- b^2 - 4*a*c
     c((-b - sqrt(d)) / (2*a), (-b + sqrt(d)) / (2*a))
   }',
  "entregas/garcia/ejercicio1.R"
)

writeLines(
  'ceros_cuadratica <- function(a, b, c) c(0, 0)',  # incorrecto
  "entregas/lopez/ejercicio1.R"
)

writeLines(
  'test_ejercicio1_raices <- function() {
     all(ceros_cuadratica(1, 0, -1) == c(-1, 1))
   }
   test_ejercicio1_tipo <- function() {
     is.numeric(ceros_cuadratica(1, 0, -1))
   }',
  "tests/test_ejercicio1.R"
)

# --- 2. Corregir ---
resultados <- grade_submissions("entregas/", test_dir = "tests/")
resultados
# <grade_results> 4 rows, 2 students, 1 exercises
# Status:
#   pass          3
#   fail          1

# --- 3. Vista resumida y exportación ---
grade_report(resultados)
export_to_html(resultados, "informe.html")
export_to_csv(resultados,  "notas.csv")
```

## Entregas y tests

Una carpeta por estudiante y un archivo de tests por ejercicio. El nombre del
archivo de tests tiene que coincidir con el del ejercicio:

```
entregas/
├── garcia_juan/
│   ├── ejercicio1.R
│   └── ejercicio2.Rmd
└── lopez_maria/
    └── ejercicio1.R

tests/
├── test_ejercicio1.R
└── test_ejercicio2.R
```

Un archivo de tests tiene funciones `test_<ejercicio>_<caso>` que devuelven
`TRUE` o `FALSE`. También pueden usar expectativas de testthat
(`expect_equal()` y otras).

```r
# tests/test_ejercicio1.R
test_ejercicio1_raices <- function() {
  all(ceros_cuadratica(1, 0, -1) == c(-1, 1))
}
```

- Los ejercicios esperados salen de la carpeta de tests. Un ejercicio que el
  estudiante no entregó queda como `missing`, no se ignora.
- Los nombres de archivo se comparan sin importar mayúsculas: `Ejercicio1.R`
  cuenta como `ejercicio1`. De `.Rmd` y `.qmd` se corren los bloques de R.
- Las entregas pueden venir en una carpeta o en un `.zip`. El nombre de cada
  estudiante sale de su carpeta (`garcia_juan` queda como `Garcia`); cambialo
  con `student_name_fn`.
- Para Moodle, pasá el `.zip` de "Descargar todas las entregas" con
  `layout = "moodle"`. Funciona con y sin "Descargar entregas en carpetas".

```r
resultados <- grade_submissions("tarea1-entregas.zip", test_dir = "tests/",
                                layout = "moodle")
```

## Qué más hace

- **Notas:** `student_scores()` da puntaje parcial y acepta pesos por test o
  por ejercicio; `grade_scale()` pasa ese puntaje a una nota de 1 a 10.
- **Devoluciones:** `export_feedback()` escribe un archivo por estudiante, en
  castellano o en inglés; `export_moodle_feedback()` las arma en un `.zip`
  para subir a Moodle.
- **Resúmenes y exportación:** `grade_report()`, `plot_report()`,
  `export_to_csv()`, `export_to_html()` y `export_to_sheets()`.
- **Entregas parecidas:** `compare_submissions()` busca copias, aunque cambien
  nombres de variables, espacios o comentarios.
- **Tiempo límite y velocidad:** cada test tiene `timeout` segundos (10 por
  defecto), y `workers` corrige varios estudiantes a la vez.
- **Para probar:** `example_results()` trae resultados de ejemplo, y
  `system.file("examples", package = "corrector")` tests para cinco
  ejercicios.

Todo esto, con ejemplos, en
[Corregir entregas de principio a fin](https://anevolbap.github.io/corrector/articles/corregir-entregas.html).

![Vista previa de los gráficos](man/figures/plots-preview.png)

## Seguridad y trampas

corrector no es un sandbox: con el motor por defecto, `callr`, el código del
estudiante corre con tu usuario y puede leer y escribir tus archivos. Bloquea
las trampas comunes (redefinir `all()`, `==` o métodos de comparación) y
anota el código sospechoso, que `grade_report()` lista para revisar a mano.

- `engine = "isolated"` corre el código del estudiante en otro proceso, así
  trucos como `attach()` no cambian la nota.
- `engine = "container"` hace lo mismo dentro de Docker, sin red y solo con
  los archivos del ejercicio, así el código tampoco llega a tu computadora.

```r
resultados <- grade_submissions("entregas/", test_dir = "tests/",
                                engine = "container", workers = 4)
```

Cómo elegir el motor, construir la imagen de Docker y escribir tests
difíciles de engañar:
[Corregir sin que te hagan trampa](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.html).

## Alternativas

corrector sirve para ejercicios que el estudiante escribe como archivo en su
propia computadora y que el docente corrige después, todos juntos, con sus
propios tests, sin servidor ni cuentas para los estudiantes. Otros paquetes de
R cubren otros casos:

- **[gradethis](https://rstudio.github.io/gradethis/)**: revisa el código
  ejercicio por ejercicio dentro de un tutorial interactivo de
  [learnr](https://rstudio.github.io/learnr/), con respuesta al instante. El
  ejercicio vive dentro del tutorial y necesita un servidor Shiny.
- **[exams](https://www.r-exams.org/)**: genera preguntas al azar y las exporta
  a Moodle, Canvas, PDF y otros formatos. Corrige respuestas (un número, una
  opción, un texto), no el código que escribió el estudiante.
- **[RTutor](https://github.com/skranz/RTutor)**: guías de problemas
  interactivas con corrección automática y seguimiento del progreso, en su
  propio formato.

corrector no es interactivo: el estudiante no ve el resultado mientras
escribe, salvo que le des los tests para que los corra.

## Contribuciones

El feedback es bienvenido. Abrí un issue en GitHub.
