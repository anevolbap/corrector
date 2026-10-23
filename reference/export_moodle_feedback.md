# Devoluciones en un .zip listo para subir a Moodle

Escribe con
[`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md)
un archivo de devolución por estudiante y lo guarda en un `.zip`, dentro
de la carpeta de Moodle de cada estudiante
(`<Nombre completo>_<id>_assignsubmission_file/devolucion.md`). En la
página de entregas de la tarea, usá la opción para subir varios archivos
de retroalimentación en un zip (en inglés, *Upload multiple feedback
files in a zip*); Moodle reconoce a cada estudiante por el número de la
carpeta. La tarea tiene que tener activada la retroalimentación con
archivos.

## Usage

``` r
export_moodle_feedback(
  results,
  zip_path,
  scoring = c("partial", "all"),
  weights = NULL,
  lang = default_lang()
)
```

## Arguments

- results:

  Un objeto
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  de `grade_submissions(layout = "moodle")`. *English:* A
  [grade_results](https://anevolbap.github.io/corrector/reference/grade_results.md)
  object from `grade_submissions(layout = "moodle")`.

- zip_path:

  Ruta del `.zip` que se escribe. *English:* Path of the `.zip` to
  write.

- scoring, weights, lang:

  Se pasan a
  [`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md).
  El archivo se llama `devolucion.md` con `lang = "es"` y `feedback.md`
  con `lang = "en"`. *English:* Passed to
  [`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md).
  The file is `devolucion.md` with `lang = "es"` and `feedback.md` with
  `lang = "en"`.

## Value

`zip_path`, de forma invisible. *English:* `zip_path`, invisibly.

## Details

Los resultados tienen que venir de
`grade_submissions(layout = "moodle")`, que guarda los nombres de las
carpetas.

## English

**Feedback in a .zip ready to upload to Moodle.** Writes one feedback
file per student with
[`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md)
and stores it in a `.zip`, inside each student's Moodle folder
(`<Full name>_<id>_assignsubmission_file/feedback.md`). On the
assignment's submissions page, use "Upload multiple feedback files in a
zip"; Moodle matches each student by the number in the folder name. The
assignment must have file feedback turned on.

The results must come from `grade_submissions(layout = "moodle")`, which
keeps the folder names.

## Examples

``` r
if (FALSE) { # \dontrun{
resultados <- grade_submissions("tarea1.zip", test_dir = "tests/",
                                layout = "moodle")
export_moodle_feedback(resultados, "devoluciones-tarea1.zip")
} # }
```
