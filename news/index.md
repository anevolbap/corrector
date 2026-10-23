# Changelog

## corrector 0.5.0

### Novedades

- `engine = "isolated"` corre el código del estudiante en una sesión de
  R separada de la de los tests. Cada función del estudiante que llaman
  los tests corre ahí y solo vuelve su resultado, como datos simples.
  Así, trucos como [`attach()`](https://rdrr.io/r/base/attach.html),
  métodos S3 para comparaciones o funciones de base reemplazadas no
  cambian la nota. Tarda alrededor del doble que `callr`.
- Cada entrega se lee en busca de código sospechoso
  ([`attach()`](https://rdrr.io/r/base/attach.html),
  [`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
  [`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
  [`trace()`](https://rdrr.io/r/base/trace.html), escrituras en el
  entorno global o en base, `parse(text = )`, …). Después de correrla,
  se revisa en busca de manipulación (entornos agregados con
  [`attach()`](https://rdrr.io/r/base/attach.html), métodos S3
  registrados, funciones de base reemplazadas). Las dos cosas se anotan
  en la columna `message`, y
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  lista a esos estudiantes en “Check by hand”. Nueva función
  [`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md).
- Los tests no ven los métodos S3 que el estudiante define para
  genéricos de comparación (`Ops`, `==`, `all.equal`, `as.logical`, …),
  salvo que estén en `allow_masking`.
- Después de cada ejercicio, el motor inproc deshace los entornos
  agregados con [`attach()`](https://rdrr.io/r/base/attach.html) y los
  métodos registrados, así no pasan al siguiente estudiante. Si el
  código del estudiante reemplazó funciones de base, da una advertencia
  para que reinicies R.
- Nuevos artículos:
  [`vignette("evaluacion-anti-trampas")`](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.md)
  y, en inglés,
  [`vignette("cheat-resistant-grading")`](https://anevolbap.github.io/corrector/articles/cheat-resistant-grading.md).

### Cambios que rompen compatibilidad

- [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
  [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md)
  y
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
  cuentan como 0 un ejercicio que falta, o uno con `source_error`. Antes
  lo dejaban afuera, así que un estudiante que entregó 1 de 5
  ejercicios, sin errores, aparecía con 100%. El puntaje del estudiante
  ahora es igual a `student_scores()$total`.

### English

#### New features

- `engine = "isolated"` runs student code in a separate R session from
  the tests. Each student function the tests call runs there and only
  its result comes back, as plain data, so tricks such as
  [`attach()`](https://rdrr.io/r/base/attach.html), S3 methods for
  comparisons, or replaced base functions do not change the grade. It
  takes about twice as long as `callr`.
- Every submission is read for suspicious code
  ([`attach()`](https://rdrr.io/r/base/attach.html),
  [`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
  [`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
  [`trace()`](https://rdrr.io/r/base/trace.html), writes into the global
  or base environment, `parse(text = )`, …) and checked after it runs
  for tampering (attached environments, registered S3 methods, replaced
  base functions). Both are noted in the `message` column, and
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  lists those students under “Check by hand”. New
  [`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md).
- Student S3 methods for comparison generics (`Ops`, `==`, `all.equal`,
  `as.logical`, …) are not visible to the tests unless listed in
  `allow_masking`.
- After each exercise, the inproc engine undoes attached environments
  and registered methods, so they do not reach the next student. If
  student code replaced base functions, it warns you to restart R.
- New articles:
  [`vignette("cheat-resistant-grading")`](https://anevolbap.github.io/corrector/articles/cheat-resistant-grading.md)
  and, in Spanish,
  [`vignette("evaluacion-anti-trampas")`](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.md).

#### Breaking changes

- [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
  [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md)
  and
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
  count a missing exercise, or one with a `source_error`, as 0. Before,
  they left it out, so a student who handed in 1 of 5 exercises, all
  correct, showed 100%. The student score is now the same as
  `student_scores()$total`.

## corrector 0.4.0

### Novedades

- Las funciones de test pueden usar expectativas de testthat. Un
  `expect_*()` que falla se registra como `fail` con su mensaje, y un
  test con todas sus expectativas cumplidas cuenta como `pass`. Los
  estudiantes no pueden redefinir funciones de testthat.
- `grade_submissions(layout = "moodle")` lee la exportación de
  “Descargar todas las entregas” de Moodle, con o sin “Descargar
  entregas en carpetas”. Nueva función
  [`moodle_student_name()`](https://anevolbap.github.io/corrector/reference/moodle_student_name.md).
- Nueva función
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md):
  puntaje parcial por ejercicio, pesos por test o por ejercicio, y un
  `total` donde los ejercicios que faltan cuentan como 0.
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  tiene los nuevos argumentos `scoring` y `weights`; sus valores por
  defecto no cambian.
- Nueva función
  [`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md):
  escribe un archivo Markdown por estudiante.
- Los estudiantes pueden entregar archivos `.Rmd` o `.qmd`; se corrigen
  sus bloques de código R.
- Los nombres de los archivos de estudiantes y de tests se comparan sin
  distinguir mayúsculas de minúsculas.
- [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md)
  y
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
  tienen los nuevos argumentos `scoring` y `weights`, como
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).

### Robustez y seguridad

- Los tests buscan los nombres en los paquetes cargados en lugar del
  entorno global, así un estudiante ya no puede fingir tests aprobados
  definiendo funciones ahí.
- El motor callr descarta la salida del estudiante. Antes, si el
  estudiante imprimía más de unos 64 KB, el subproceso se trababa y
  todos los tests daban timeout.
- El tiempo límite también se aplica mientras se carga el archivo del
  estudiante. Un archivo que nunca termina de cargar da `timeout` en
  todos los tests; antes, el motor inproc se colgaba.
- [`quit()`](https://rdrr.io/r/base/quit.html) y
  [`q()`](https://rdrr.io/r/base/quit.html) en el código del estudiante
  generan un error en lugar de cerrar la sesión. El motor inproc
  restaura el directorio de trabajo y las opciones.
- Cuando el motor callr interrumpe un ejercicio, los tests que ya
  terminaron conservan su resultado.
- Si un archivo de tests no se puede cargar, la corrección se detiene
  con un error claro antes de corregir a nadie; antes, el motor callr
  devolvía cero filas sin avisar. Un archivo de tests sin funciones
  `test_<exercise>_*` da una advertencia una sola vez.
- [`skip()`](https://testthat.r-lib.org/reference/skip.html) de testthat
  dentro de un test se registra como `error` en lugar de abortar.
- El paquete rechaza las entradas de un zip que apuntan fuera de la
  carpeta de extracción.
- Las exportaciones a CSV y Google Sheets ponen un `'` antes del texto
  que una planilla ejecutaría como fórmula.
- Errores claros para rutas que no existen y para valores incorrectos de
  `timeout` o `workers`, y una advertencia cuando no hay carpetas de
  estudiantes.
- Casos borde corregidos: nombres de estudiante `NA`, una sola carpeta
  de estudiante con solo archivos `.Rmd`, resultados vacíos en
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  y
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md),
  nombres de archivos de devolución que chocan entre sí, y ejercicios
  llamados `student` o `total`.

### Otros

- Los tres argumentos de patrón que las notas de la versión 0.2.0
  listaban por error (`exercise_pattern`, `test_file_template`,
  `test_fn_pattern`) no se van a agregar: los nombres de los ejercicios
  ya salen de los nombres de los archivos de tests.

### English

#### New features

- Test functions can use testthat expectations. A failed `expect_*()` is
  recorded as `fail` with its message, and a test whose expectations all
  pass counts as `pass`. Students cannot redefine testthat functions.
- `grade_submissions(layout = "moodle")` reads the export from Moodle’s
  “Download all submissions”, with or without “Download submissions in
  folders”. New
  [`moodle_student_name()`](https://anevolbap.github.io/corrector/reference/moodle_student_name.md).
- New
  [`student_scores()`](https://anevolbap.github.io/corrector/reference/student_scores.md):
  partial credit per exercise, weights per test or per exercise, and a
  `total` where missing exercises count as 0.
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  gains `scoring` and `weights`; its defaults are unchanged.
- New
  [`export_feedback()`](https://anevolbap.github.io/corrector/reference/export_feedback.md)
  writes one Markdown file per student.
- Students can hand in `.Rmd` or `.qmd` files; their R chunks are
  graded.
- Student and test file names are matched ignoring case.
- [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md)
  and
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md)
  gain `scoring` and `weights`, like
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md).

#### Hardening

- Tests look up names in the attached packages instead of the global
  environment, so a student can no longer forge passes by assigning
  functions there.
- The callr engine discards student output. Before, more than about 64
  KB of printed output stalled the subprocess, and every test timed out.
- The time limit also applies while loading the student’s file. A file
  that never finishes loading gives `timeout` on every test; before, the
  inproc engine hung.
- [`quit()`](https://rdrr.io/r/base/quit.html) and
  [`q()`](https://rdrr.io/r/base/quit.html) in student code raise an
  error instead of ending the session. The inproc engine restores the
  working directory and options.
- When the callr engine kills an exercise, tests that already finished
  keep their result.
- A test file that fails to load stops grading with a clear error before
  anyone is graded; before, the callr engine returned zero rows in
  silence. A test file without `test_<exercise>_*` functions warns once.
- testthat [`skip()`](https://testthat.r-lib.org/reference/skip.html) in
  a test is recorded as `error` instead of aborting.
- Zip entries that point outside the extraction folder are refused.
- CSV and Google Sheets exports put a `'` before text that a spreadsheet
  would run as a formula.
- Clear errors for missing paths and bad `timeout` or `workers` values,
  and a warning when there are no student folders.
- Fixed edge cases: `NA` student names, a single student folder with
  only `.Rmd` files, empty results in
  [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
  and
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md),
  colliding feedback file names, and exercises named `student` or
  `total`.

#### Other

- The three pattern arguments listed by mistake in the 0.2.0 notes
  (`exercise_pattern`, `test_file_template`, `test_fn_pattern`) will not
  be added: exercise names already come from the test file names.

## corrector 0.3.1

- Corregido: el código de estudiantes y de tests solo podía usar R base.
  Llamadas como [`median()`](https://rdrr.io/r/stats/median.html),
  [`sd()`](https://rdrr.io/r/stats/sd.html),
  [`rnorm()`](https://rdrr.io/r/stats/Normal.html) o
  [`head()`](https://rdrr.io/r/utils/head.html) fallaban con “could not
  find function”, y [`library()`](https://rdrr.io/r/base/library.html)
  en un archivo de tests no tenía efecto. Ahora el código ve los
  paquetes cargados.
- Todas las funciones exportadas tienen ejemplos.
- Se arma y se publica un sitio pkgdown en
  <https://anevolbap.github.io/corrector/>.
- DESCRIPTION describe los resultados actuales por test y el motor
  callr.
- Preparado para el primer envío a CRAN (`cran-comments.md`).

### English

- Fixed: student and test code could only use base R. Calls such as
  [`median()`](https://rdrr.io/r/stats/median.html),
  [`sd()`](https://rdrr.io/r/stats/sd.html),
  [`rnorm()`](https://rdrr.io/r/stats/Normal.html) or
  [`head()`](https://rdrr.io/r/utils/head.html) failed with “could not
  find function”, and [`library()`](https://rdrr.io/r/base/library.html)
  in a test file had no effect. Code now sees the attached packages.
- Every exported function has examples.
- A pkgdown site is built and deployed to
  <https://anevolbap.github.io/corrector/>.
- DESCRIPTION describes the current per-test results and the callr
  engine.
- Prepared for the first CRAN submission (`cran-comments.md`).

## corrector 0.3.0

### Cambios que rompen compatibilidad

- El motor por defecto ahora es `"callr"` y el `timeout` por defecto es
  de 10 segundos por test, tanto en
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  como en
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).
  Pasá `engine = "inproc"` y `timeout = Inf` para volver al
  comportamiento anterior. `callr` pasó de Suggests a Imports.

### Novedades

- `grade_submissions(workers = )` corre varios subprocesos de callr al
  mismo tiempo. Los resultados mantienen el mismo orden que con un solo
  worker.
- El subproceso de callr corre en su propio directorio de trabajo
  temporal, así los archivos que escribe un estudiante no caen en tu
  carpeta.

### Correcciones

- El motor callr ahora da una advertencia ante un `source_error`, como
  el motor inproc.
- El motor callr devuelve cero filas en lugar de un error cuando un
  archivo de tests no define funciones de test para el ejercicio.

### Otros

- La CI hace chequeos en macOS y Windows, y un workflow de cobertura
  corre covr.
- Los README y la viñeta dicen que corrector no es un sandbox de
  seguridad.

### English

#### Breaking changes

- The default engine is now `"callr"` and the default `timeout` is 10
  seconds per test, for both
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  and
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md).
  Pass `engine = "inproc"` and `timeout = Inf` for the old behavior.
  `callr` moved from Suggests to Imports.

#### New features

- `grade_submissions(workers = )` runs several callr subprocesses at the
  same time. Results keep the same order as with one worker.
- The callr subprocess runs in its own temporary working directory, so
  files a student writes do not land in your folder.

#### Bug fixes

- The callr engine now warns on `source_error`, like the inproc engine.
- The callr engine returns zero rows instead of an error when a test
  file defines no test functions for the exercise.

#### Other

- CI checks on macOS and Windows, and a coverage workflow runs covr.
- The READMEs and the vignette say that corrector is not a security
  sandbox.

## corrector 0.2.1

### Correcciones

- El código del estudiante ya no puede pasar tests redefiniendo
  funciones de base como [`all()`](https://rdrr.io/r/base/all.html) o
  `==`. Los tests corren en su propio entorno, y no ven los objetos del
  estudiante que enmascaran una función de R base o de los paquetes por
  defecto. Los nombres ignorados se listan en la columna `message`.
  Nuevo argumento `allow_masking` en
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  y
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  para ejercicios que piden a los estudiantes escribir una función así
  (por ejemplo `factorial`).
- El motor inproc ya no corre las funciones `test_*` definidas en el
  archivo del estudiante.
- Los estudiantes cuyas carpetas dan el mismo nombre para mostrar ya no
  se juntan. Conservan los nombres de sus carpetas, con una advertencia.
- Los archivos de estudiantes en Latin-1 se cargan bien en lugar de
  fallar con `source_error`.
- [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  ignora archivos sueltos, carpetas ocultas y `__MACOSX`, y entra en una
  única carpeta de nivel superior (una carpeta padre comprimida en zip).
- `R CMD check` ahora corre los tests del paquete (faltaba
  `tests/testthat.R`).
- Las notas de la versión 0.2.0 listaban los argumentos
  `exercise_pattern`, `test_file_template` y `test_fn_pattern`, que
  nunca se implementaron. Se quitaron de las notas de abajo.

### English

#### Bug fixes

- Student code can no longer pass tests by redefining base functions
  such as [`all()`](https://rdrr.io/r/base/all.html) or `==`. Tests run
  in their own environment, and student objects that mask a function
  from base R or the default packages are not visible to them. The
  ignored names are listed in the `message` column. New `allow_masking`
  argument on
  [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  and
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  for exercises that ask students to write such a function (e.g.
  `factorial`).
- The inproc engine no longer runs `test_*` functions defined in the
  student file.
- Students whose folders map to the same display name are no longer
  merged. They keep their folder names, with a warning.
- Latin-1 student files are sourced instead of failing with
  `source_error`.
- [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  ignores loose files, hidden folders and `__MACOSX`, and steps into a
  single top-level folder (a zipped parent folder).
- `R CMD check` now runs the test suite (`tests/testthat.R` was
  missing).
- The 0.2.0 notes listed `exercise_pattern`, `test_file_template` and
  `test_fn_pattern` arguments that were never implemented. They are
  removed from the notes below.

## corrector 0.2.0

### Cambios que rompen compatibilidad

- [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  y
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  ahora devuelven un objeto `grade_results`: un data frame en formato
  largo con una fila por test, con las columnas `student`, `exercise`,
  `test`, `status`, `message`, `duration`. El data frame anterior en
  formato ancho, con pass/fail, sigue disponible con
  `as.data.frame(results, format = "wide")`.
- `status` es un factor con los niveles `pass`, `fail`, `error`,
  `timeout`, `missing`, `source_error`. Antes, todos estos casos se
  juntaban en un solo “all FALSE”.
- [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md),
  [`export_to_csv()`](https://anevolbap.github.io/corrector/reference/export_to_csv.md),
  [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md)
  y
  [`export_to_sheets()`](https://anevolbap.github.io/corrector/reference/export_to_sheets.md)
  usan el nuevo objeto. CSV usa el formato ancho por defecto, por
  compatibilidad con versiones anteriores; pasá `format = "long"` para
  conservar el detalle por test.

### Novedades

- `engine = "callr"` corre cada test en un subproceso con el paquete
  [callr](https://callr.r-lib.org/). Así hay un timeout estricto, medido
  en tiempo real, que sí interrumpe los bucles que ocupan la CPU. El
  valor por defecto sigue siendo `"inproc"`.
- Nuevo argumento `student_name_fn` en
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md):
  una función que se aplica al nombre de cada carpeta de estudiante para
  obtener el nombre para mostrar. Por defecto usa el comportamiento
  anterior: la primera parte separada por guion bajo, con mayúscula
  inicial.
- `plot_report(backend = "ggplot2")` genera los tres gráficos con
  ggplot2 cuando el paquete está instalado; si no, usa R base.
- Los mensajes de progreso usan [cli](https://cli.r-lib.org/) cuando
  está disponible.

### Correcciones

- `find_test_file()` ya no trata el nombre de archivo del ejercicio como
  una expresión regular.
- La detección de zip no distingue mayúsculas de minúsculas; los
  archivos comprimidos se extraen en
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) en lugar de al
  lado del archivo de entrada.

### English

#### Breaking changes

- [`grade_exercise()`](https://anevolbap.github.io/corrector/reference/grade_exercise.md)
  and
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md)
  now return a `grade_results` object: a long-format data frame with one
  row per test, with columns `student`, `exercise`, `test`, `status`,
  `message`, `duration`. The previous wide pass/fail data frame is still
  available via `as.data.frame(results, format = "wide")`.
- `status` is a factor with levels `pass`, `fail`, `error`, `timeout`,
  `missing`, `source_error`. Distinct from the old “all FALSE” collapse.
- [`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md),
  [`plot_report()`](https://anevolbap.github.io/corrector/reference/plot_report.md),
  [`export_to_csv()`](https://anevolbap.github.io/corrector/reference/export_to_csv.md),
  [`export_to_html()`](https://anevolbap.github.io/corrector/reference/export_to_html.md),
  and
  [`export_to_sheets()`](https://anevolbap.github.io/corrector/reference/export_to_sheets.md)
  consume the new object. CSV defaults to wide for backward
  compatibility; pass `format = "long"` to keep the per-test detail.

#### New features

- `engine = "callr"` runs each test in a subprocess via the
  [callr](https://callr.r-lib.org/) package, giving a hard wall-clock
  timeout that actually interrupts busy loops. Default stays `"inproc"`.
- New `student_name_fn` argument on
  [`grade_submissions()`](https://anevolbap.github.io/corrector/reference/grade_submissions.md):
  function applied to each student folder name to produce the display
  name. Defaults to the previous “first underscore-separated token,
  title case” behavior.
- `plot_report(backend = "ggplot2")` produces the three plots with
  ggplot2 when the package is installed; falls back to base R otherwise.
- Progress messages use [cli](https://cli.r-lib.org/) when available.

#### Bug fixes

- `find_test_file()` no longer treats the exercise filename as a regex.
- Zip detection is case-insensitive; archives are extracted into
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) rather than next
  to the input.

## corrector 0.1.0

- Primera versión con el nombre `corrector` (antes `autocorrectoR`).

### English

- First release under the name `corrector` (previously `autocorrectoR`).
