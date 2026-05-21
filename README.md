# corrector

[English version](README.en.md)

Paquete de R para corregir automáticamente ejercicios de programación. Cada
estudiante entrega un archivo `.R` por ejercicio y el docente provee los archivos
de tests. El paquete los carga en un entorno aislado, ejecuta los tests y
devuelve un objeto con los resultados por test.

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
#   pass  2
#   fail  2

# --- 3. Vista resumida y exportación ---
grade_report(resultados)
export_to_html(resultados, "informe.html")
export_to_csv(resultados,  "notas.csv")
```

El paquete incluye datos de ejemplo para probar las funciones sin necesidad de
armar entregas reales:

```r
resultados <- example_results()  # 8 estudiantes ficticios, 5 ejercicios
grade_report(resultados)
plot_report(resultados)
```

## Estructura de los resultados

`grade_submissions()` y `grade_exercise()` devuelven un objeto `grade_results`,
un data frame en formato largo con una fila por (estudiante, ejercicio, test):

| student | exercise   | test                    | status | message | duration |
|---------|------------|-------------------------|--------|---------|----------|
| Garcia  | ejercicio1 | test_ejercicio1_raices  | pass   | NA      | 0.001    |
| Lopez   | ejercicio1 | test_ejercicio1_raices  | fail   | NA      | 0.001    |

`status` es un factor con niveles `pass`, `fail`, `error`, `timeout`, `missing`,
`source_error`. Esto permite distinguir un test que devolvió `FALSE` de uno que
arrojó un error, agotó el tiempo límite, o de un archivo que el estudiante no
entregó.

Para obtener la vista clásica (una fila por estudiante, una columna lógica por
ejercicio):

```r
as.data.frame(resultados, format = "wide")
#   student    ejercicio1
# 1 Garcia          TRUE
# 2 Lopez          FALSE
```

`NA` indica que el ejercicio no se entregó o que el archivo no parseó.

## Cómo funciona

El corrector usa la siguiente convención de nombres:

```
entregas/
├── garcia_juan/
│   ├── ejercicio1.R   <- archivo del estudiante
│   └── ejercicio2.R
└── lopez_maria/
    ├── ejercicio1.R
    └── ejercicio2.R

tests/
├── test_ejercicio1.R  <- archivo de tests del docente (el nombre tiene que coincidir)
└── test_ejercicio2.R
```

Cada archivo de tests tiene funciones con el formato `test_<ejercicio>_<caso>`
que devuelven `TRUE` o `FALSE`:

```r
# tests/test_ejercicio1.R
test_ejercicio1_raices <- function() {
  all(ceros_cuadratica(1, 0, -1) == c(-1, 1))
}

test_ejercicio1_tipo <- function() {
  is.numeric(ceros_cuadratica(1, 0, -1))
}
```

La lista de ejercicios esperados sale del directorio de tests: cada archivo
`test_*.R` define un ejercicio. Si un estudiante no entrega un ejercicio que
existe en `test_dir/`, se registra una fila con `status = missing` en lugar de
ignorarlo en silencio.

El código del estudiante y los tests se cargan en un entorno nuevo y aislado
para cada ejercicio, así las entregas no se interfieren entre sí.

## Uso

```r
library(corrector)

# Corregir un lote completo (carpeta o .zip)
resultados <- grade_submissions("entregas/", test_dir = "tests/")

# Corregir un archivo individual (útil mientras escribís los tests)
grade_exercise("entregas/garcia_juan/ejercicio1.R", test_dir = "tests/")

# Resumen en consola
grade_report(resultados)
# === Grade Report ===
#
# Pass rate by exercise:
#   ejercicio1                50%
#   ejercicio2               100%
#
# Overall mean score: 75%
#
# Score by student (descending):
#   Garcia               #################### 100%
#   Lopez                ##########            50%

# Exportar
export_to_csv(resultados, "notas.csv")               # vista wide por defecto
export_to_csv(resultados, "notas-largo.csv", format = "long")
export_to_html(resultados, "informe.html")           # tabla con colores y detalle por test

# Exportar a Google Sheets (requiere googlesheets4)
googlesheets4::gs4_auth()
export_to_sheets(resultados, "https://docs.google.com/spreadsheets/d/...")
```

## Gráficos

`plot_report()` genera tres gráficos en secuencia: puntajes de los estudiantes
ordenados, tasa de aprobación por ejercicio y un mapa de calor de resultados.

```r
# Interactivo, pausa entre gráficos
plot_report(resultados)

# Guardar los tres gráficos en un PDF
pdf("informe.pdf", width = 8, height = 5)
plot_report(resultados, ask = FALSE)
dev.off()

# Usar ggplot2 si está instalado (vuelve a base R si no)
plot_report(resultados, backend = "ggplot2")
```

![Vista previa de los gráficos](man/figures/plots-preview.png)

## Tiempo límite por test

Para evitar que bucles infinitos en el código de los estudiantes bloqueen el
corrector, definí un límite de tiempo en segundos:

```r
resultados <- grade_submissions("entregas/", test_dir = "tests/", timeout = 10)
```

Por defecto el corrector usa `setTimeLimit()` dentro de la sesión actual.
Funciona para casos comunes pero no siempre interrumpe `Sys.sleep()` ni todos
los bucles cerrados. Para un corte real por reloj de pared, usá el motor
`callr`:

```r
resultados <- grade_submissions(
  "entregas/", test_dir = "tests/",
  timeout = 10, engine = "callr"
)
```

`callr` corre cada ejercicio en un subproceso fresco y lo mata cuando excede el
presupuesto. Requiere el paquete `callr` instalado.

## Archivos de tests de ejemplo

El paquete incluye ejemplos para cinco tipos de ejercicio: raíces de ecuación
cuadrática, búsqueda de palabras, ordenamiento, simulación y transformación de
data frames.

```r
system.file("examples", package = "corrector")
```

## Alternativas

Otros paquetes de R que resuelven problemas similares, cada uno con un alcance
distinto:

- **[gradethis](https://pkgs.rstudio.com/gradethis/)**: verifica código dentro
  de tutoriales interactivos de [learnr](https://rstudio.github.io/learnr/).
  Ideal para práctica guiada, pero requiere un servidor Shiny.
- **[exams](https://www.r-exams.org/)**: genera preguntas de examen
  aleatorizadas y exporta a Moodle, Canvas, PDF y otros formatos. Muy poderoso
  para cursos grandes que se repiten año a año.
- **[RTutor](https://github.com/skranz/RTutor)**: crea guías de problemas
  interactivas con corrección automática y seguimiento del progreso.

corrector es la opción más liviana: sin servidor, sin infraestructura,
entregas en archivos `.R` comunes y sin dependencias obligatorias.

## Contribuciones

El feedback es bienvenido. Abrí un issue en GitHub.

## Nombres de las carpetas

Se espera que las carpetas de cada estudiante empiecen con el apellido,
opcionalmente seguido de otros campos separados por guiones bajos
(por ejemplo `garcia_juan_12345`). El corrector extrae el primer segmento como
nombre para mostrar.

Para usar otra convención, pasá una función a `student_name_fn`:

```r
resultados <- grade_submissions(
  "entregas/", test_dir = "tests/",
  student_name_fn = function(folder) sub("_.*$", "", folder)
)
```

Las entregas también se pueden entregar como un único archivo `.zip`; el paquete
lo descomprime automáticamente antes de corregir.
