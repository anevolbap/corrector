# Nombre del estudiante a partir de una carpeta de Moodle

"Descargar todas las entregas" de Moodle nombra cada carpeta
`<Nombre completo>_<id>_assignsubmission_file`. Esta función se queda
con el nombre completo. Con calificación anónima (*blind marking*) todas
las carpetas empiezan con "Participante", así que los nombres se repiten
y
[`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
usa los nombres de las carpetas.

## Usage

``` r
moodle_student_name(folder)
```

## Arguments

- folder:

  Texto. Nombre de la carpeta de la entrega. *English:* Character.
  Submission folder name.

## Value

Texto. Nombre para mostrar. *English:* Character. Display name.

## English

**Student name from a Moodle submission folder.** Moodle's "Download all
submissions" names each folder `<Full name>_<id>_assignsubmission_file`.
This keeps the full name. With blind marking every folder starts with
"Participant", so names clash and
[`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
falls back to the folder names.

## Examples

``` r
moodle_student_name("Juan Perez_123456_assignsubmission_file")
#> [1] "Juan Perez"
```
