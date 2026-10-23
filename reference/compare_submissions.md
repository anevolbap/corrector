# Buscar entregas parecidas entre estudiantes

Compara, para cada ejercicio, los archivos de todos los pares de
estudiantes y devuelve los pares con una similitud de al menos
`min_similarity`, del más parecido al menos parecido. Sirve para
detectar entregas copiadas.

## Usage

``` r
compare_submissions(
  submissions_path,
  layout = c("folders", "moodle"),
  min_similarity = 0.7,
  student_name_fn = default_student_name,
  k = 5
)
```

## Arguments

- submissions_path:

  Carpeta o archivo `.zip` con las entregas, como en
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).
  *English:* Folder or `.zip` of submissions, as in
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).

- layout:

  `"folders"` o `"moodle"`, como en
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).
  *English:* `"folders"` or `"moodle"`, as in
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).

- min_similarity:

  Similitud mínima (entre 0 y 1) de los pares que se devuelven. Por
  defecto 0.7. *English:* Minimum similarity (between 0 and 1) of the
  returned pairs. Default 0.7.

- student_name_fn:

  Función para el nombre de cada estudiante, como en
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).
  *English:* Function for each student's name, as in
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).

- k:

  Largo de los grupos de elementos que se comparan. Valores más chicos
  encuentran más coincidencias. Por defecto 5. *English:* Length of the
  token runs that are compared. Smaller values find more matches.
  Default 5.

## Value

Un data frame con las columnas `exercise`, `student_a`, `student_b` y
`similarity` (entre 0 y 1). *English:* A data frame with columns
`exercise`, `student_a`, `student_b` and `similarity` (between 0 and 1).

## Details

Cada archivo se convierte en una secuencia de elementos de R sin
comentarios ni espacios. Los nombres de variables, los textos y los
números se reemplazan por marcadores, así que cambiar nombres o el
formato no esconde una copia. Las llamadas a funciones conservan el
nombre, salvo las funciones que define el mismo archivo. La similitud es
la proporción de grupos de `k` elementos seguidos que comparten los dos
archivos (índice de Jaccard). Los ejercicios se reconocen por el nombre
del archivo, sin importar mayúsculas; se leen archivos `.R`, `.Rmd` y
`.qmd`.

Una similitud alta no prueba una copia: soluciones cortas o muy guiadas
se parecen naturalmente. Usala para elegir qué entregas mirar a mano.

## English

**Find similar submissions between students.** For each exercise,
compares the files of every pair of students and returns the pairs with
a similarity of at least `min_similarity`, most similar first. Use it to
spot copied work.

Each file becomes a sequence of R tokens without comments or spacing.
Variable names, strings and numbers are replaced by placeholders, so
renaming or reformatting does not hide a copy. Function calls keep their
names, except functions the file defines itself. The similarity is the
share of runs of `k` tokens that both files have (Jaccard index).
Exercises are matched by file name, ignoring case; `.R`, `.Rmd` and
`.qmd` files are read.

A high similarity does not prove copying: short or guided solutions look
alike. Use it to pick which submissions to read by hand.

## Examples

``` r
root <- file.path(tempdir(), "copias")
for (s in c("ana", "beto", "carla")) dir.create(file.path(root, s), recursive = TRUE)
writeLines("doble <- function(x) x * 2", file.path(root, "ana", "ejercicio1.R"))
writeLines("doble<-function(valor) valor*2  # mio", file.path(root, "beto", "ejercicio1.R"))
writeLines("doble <- function(x) x + x", file.path(root, "carla", "ejercicio1.R"))
compare_submissions(root, min_similarity = 0)
#>     exercise student_a student_b similarity
#> 1 ejercicio1       Ana      Beto  1.0000000
#> 2 ejercicio1       Ana     Carla  0.4285714
#> 3 ejercicio1      Beto     Carla  0.4285714
```
