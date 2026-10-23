# Corregir sin que te hagan trampa

*[English
version](https://anevolbap.github.io/corrector/articles/cheat-resistant-grading.md)*

El archivo de un estudiante es código R, y el código R puede cambiar
cómo se comporta otro código R. Este artículo muestra qué hace el
corrector al respecto, qué motor conviene elegir y cómo escribir tests
difíciles de engañar.

## Qué frena cada motor

Con los motores `callr` e `inproc`, los tests corren en el mismo proceso
de R que el código del estudiante. Ahí el corrector bloquea las trampas
comunes:

- Si el estudiante redefine una función de base R que usan los tests
  ([`all()`](https://rdrr.io/r/base/all.html), `==`,
  [`isTRUE()`](https://rdrr.io/r/base/Logic.html),
  [`expect_equal()`](https://testthat.r-lib.org/reference/equality-expectations.html)
  de testthat, etc.), los tests no ven esa versión.
- Los tests tampoco ven los métodos S3 del estudiante para las funciones
  de comparación (`Ops`, `==`, `all.equal`, `as.logical`, …).
- Las funciones que el estudiante escribe en el entorno global no les
  llegan a los tests.
- [`quit()`](https://rdrr.io/r/base/quit.html) da un error.

Si el ejercicio pide definir uno de esos nombres, permitilo con
`allow_masking`; por ejemplo `allow_masking = "Ops.dinero"` para un
ejercicio sobre una clase S3.

Un estudiante que conozca R a fondo todavía puede saltear esto, porque
su código puede cambiar el proceso mismo: hacer
[`attach()`](https://rdrr.io/r/base/attach.html) de un
[`isTRUE()`](https://rdrr.io/r/base/Logic.html) falso, registrar un
método S3 con
[`registerS3method()`](https://rdrr.io/r/base/ns-internal.html) o
reemplazar una función de base con
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html). Con estos
motores ese código queda anotado (ver más abajo), pero igual puede
cambiar la nota.

`engine = "isolated"` cierra ese hueco. Los tests corren en un proceso
de R y el código del estudiante en otro. Cada función del estudiante que
llaman los tests corre en el proceso del estudiante, y solo vuelve su
resultado, como datos. Nada de lo que el estudiante haga en su propio
proceso llega al proceso que compara los valores. Una función del
estudiante que devuelve una función, un entorno o una expresión de R da
`error`, porque eso podría traer código de vuelta.

``` r

resultados <- grade_submissions("entregas/", test_dir = "tests/",
                                engine = "isolated", workers = 4)
```

El costo es tiempo: cada ejercicio arranca dos procesos de R. En una
máquina, 10 estudiantes con 5 tests cada uno tardaron 9 s con `callr` y
20 s con `isolated`, los dos con un solo worker. `workers` corrige
varios estudiantes a la vez con cualquiera de los dos motores.

`engine = "container"` corre esos dos procesos dentro de un contenedor
de Docker sin red, con memoria y procesos limitados, el sistema en solo
lectura y solo los archivos del ejercicio. Así el código del estudiante
tampoco llega a tus archivos, a tu red ni a las entregas de los demás.
Construí la imagen una vez con el archivo que trae el paquete (agregale
los paquetes que usen los estudiantes o los tests, porque el contenedor
no tiene red):

``` bash
docker build -t corrector-runner "$(Rscript -e 'cat(system.file("container", package = "corrector"))')"
```

Cada ejercicio tarda unos segundos más, por el arranque del contenedor.

## Cómo leer las notas

Con cualquier motor, el corrector lee cada archivo del estudiante antes
de correrlo y anota en la columna `message`, como
`suspicious code: ...`, las llamadas a
[`attach()`](https://rdrr.io/r/base/attach.html),
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
[`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
[`trace()`](https://rdrr.io/r/base/trace.html) o `parse(text = )`, y las
escrituras en el entorno global o en base. Después de correr el código,
anota lo que realmente cambió (entornos agregados con
[`attach()`](https://rdrr.io/r/base/attach.html), métodos S3
registrados, funciones de base reemplazadas) como `tampering: ...`.
[`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md)
hace la primera revisión por separado.

Las notas no cambian el resultado de ningún test.
[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
lista a los estudiantes que tienen alguna en “Check by hand”, para que
revises esos archivos a mano:

``` r

grade_report(resultados)
#> ...
#> Check by hand (suspicious code or tampering, see the message column):
#>   Lopez
```

## Tests difíciles de engañar

Estos hábitos ayudan con cualquier motor. Frenan las trampas con métodos
S3 incluso con `callr` e `inproc`. No frenan
[`attach()`](https://rdrr.io/r/base/attach.html) ni funciones de base
reemplazadas en esos motores (un estudiante también puede agregar un
[`identical()`](https://rdrr.io/r/base/identical.html) falso con
[`attach()`](https://rdrr.io/r/base/attach.html)); eso solo lo frena el
motor aislado.

Compará con [`identical()`](https://rdrr.io/r/base/identical.html). No
despacha según la clase de sus argumentos y además compara la clase, así
que un objeto del estudiante con su propio método `==` o
[`all.equal()`](https://rdrr.io/r/base/all.equal.html) no pasa:

``` r

test_ejercicio1_raices <- function() {
  identical(ceros_cuadratica(1, 0, -1), c(-1, 1))
}
```

Para números que necesitan tolerancia, revisá que el resultado sea un
número común antes de comparar:

``` r

test_ejercicio1_media <- function() {
  x <- media(c(1, 2, 4))
  is.double(x) && !is.object(x) && isTRUE(all.equal(x, 7 / 3))
}
```

Con testthat, preferí
[`expect_identical()`](https://testthat.r-lib.org/reference/equality-expectations.html)
y
[`expect_type()`](https://testthat.r-lib.org/reference/inheritance-expectations.html).

Usá datos que el estudiante no pueda conocer de antemano. Un estudiante
que vio los tests puede escribir las respuestas a mano; datos al azar
comparados con una solución de referencia dentro del archivo de tests lo
impiden:

``` r

test_ejercicio2_ordenar <- function() {
  x <- sample(100, 20)
  identical(ordenar(x), sort(x))
}
```

## Lo que todavía se puede hacer

- El código del estudiante corre con tu usuario, así que puede leer
  cualquier archivo que puedas leer vos, incluidos los archivos de tests
  y las soluciones de referencia que tengan. También puede escribir
  cualquier archivo que puedas escribir vos, incluidos los archivos
  temporales del corrector y las entregas de otros estudiantes, y lanzar
  programas que siguen corriendo después de la corrección. El motor
  aislado deja el código del estudiante fuera del proceso que compara
  los valores, pero no puede frenar ataques a través de los archivos. El
  motor `"container"` sí: dentro del contenedor el estudiante solo ve
  los archivos de su ejercicio. Igual tratá los archivos de tests como
  visibles para los estudiantes, porque el test está entre esos
  archivos.
- Dentro del contenedor, el código del estudiante comparte la carpeta
  donde el proceso de los tests deja su resultado. Un estudiante que
  estudie cómo funciona el corrector podría, en principio, falsificar su
  propio resultado. El contenedor protege tu computadora; no vuelve
  imposible hacer trampa para quien estudia el paquete.
- Una función del estudiante devuelve lo que quiera su autor. Si los
  tests usan datos fijos, alcanza con una tabla de respuestas; los datos
  al azar lo impiden.
- Las revisiones de arriba buscan trampas conocidas. El código que las
  esconde suele aparecer igual como `suspicious code` (por ejemplo, una
  llamada a `parse(text = )` o un nombre sospechoso dentro de un texto),
  pero no siempre.

corrector no es un sandbox. La sección de
[seguridad](https://anevolbap.github.io/corrector/#seguridad) del README
da más detalles.
