# Objeto con los resultados de la corrección

Un objeto `grade_results` es un data frame en formato largo con una fila
por (estudiante, ejercicio, test) y estas columnas:

- `student`:

  Texto. Nombre del estudiante para mostrar.

- `exercise`:

  Texto. Identificador del ejercicio (nombre del archivo sin extensión).

- `test`:

  Texto. Nombre de la función de test, o `NA` cuando la fila registra
  una entrega `missing` o un `source_error`.

- `status`:

  Factor con niveles `pass`, `fail`, `error`, `timeout`, `missing`,
  `source_error`.

- `message`:

  Texto. El mensaje de error para `error`, `source_error` y `timeout`;
  el mensaje de testthat o "test returned non-logical" para algunas
  filas `fail`; una nota con las definiciones del estudiante que se
  ignoraron (ver `allow_masking` en
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md));
  `NA` en los demás casos.

- `duration`:

  Numérico. Segundos que tardó el test, o `NA` cuando el test no se
  ejecutó.

## Details

Usá [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) con
`format = "wide"` para obtener la vista anterior en formato ancho (una
columna lógica por ejercicio, `TRUE` si y solo si pasaron todos los
tests).

## English

**Grading results object.** A `grade_results` object is a data frame in
long format with one row per (student, exercise, test) and the following
columns:

- `student`:

  Character. Student display name.

- `exercise`:

  Character. Exercise identifier (file stem).

- `test`:

  Character. Test function name, or `NA` when the row records a
  `missing` submission or a `source_error`.

- `status`:

  Factor with levels `pass`, `fail`, `error`, `timeout`, `missing`,
  `source_error`.

- `message`:

  Character. The error message for `error`, `source_error` and
  `timeout`; the testthat message or "test returned non-logical" for
  some `fail` rows; a note listing ignored student definitions (see
  `allow_masking` in
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md));
  `NA` otherwise.

- `duration`:

  Numeric. Seconds elapsed running the test, or `NA` when the test was
  not run.

Use [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) with
`format = "wide"` to get the old wide-boolean view (one logical column
per exercise, `TRUE` iff all tests passed).
