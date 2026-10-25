# Cheat-resistant grading

*[Versión en
español](https://anevolbap.github.io/corrector/articles/evaluacion-anti-trampas.md)*

A student file is R code, and R code can change how other R code
behaves. This article shows what corrector does about that, which engine
to pick, and how to write tests that are hard to fool.

## What each engine stops

With the `callr` and `inproc` engines the tests run in the same R
process as the student code. corrector blocks the common tricks there:

- A student object that redefines a base function the tests use
  ([`all()`](https://rdrr.io/r/base/all.html), `==`,
  [`isTRUE()`](https://rdrr.io/r/base/Logic.html), testthat’s
  `expect_equal()`, and so on) is not visible to the tests.
- Student S3 methods for the comparison generics (`Ops`, `==`,
  `all.equal`, `as.logical`, …) are not visible to the tests either.
- Functions written into the global environment are not visible to the
  tests.
- [`quit()`](https://rdrr.io/r/base/quit.html) raises an error.

Allow a name with `allow_masking` when the exercise asks for it, for
example `allow_masking = "Ops.dinero"` for an exercise about an S3
class.

A student who knows R well can still get around this, because their code
can change the process itself:
[`attach()`](https://rdrr.io/r/base/attach.html) a fake
[`isTRUE()`](https://rdrr.io/r/base/Logic.html), register an S3 method
with [`registerS3method()`](https://rdrr.io/r/base/ns-internal.html), or
replace a base function with
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html). On these
engines such code is reported (see below), but it can still change the
grade.

`engine = "isolated"` closes that gap. The tests run in one R process
and the student code in another. Each student function the tests call
runs in the student process, and only its result comes back, as plain
data. Nothing the student does to their own process reaches the process
that compares the values. A student function that returns a function, an
environment or an R expression gets an `error`, because those could
carry code back.

``` r

results <- grade_submissions("submissions/", test_dir = "tests/",
                             engine = "isolated", workers = 4)
```

The cost is time: each exercise starts two R processes. On one machine,
10 students with 5 tests each took 9 s with `callr` and 20 s with
`isolated`, both with one worker. `workers` runs students in parallel on
either engine.

`engine = "container"` runs those two processes inside a Docker
container with no network, limited memory and processes, a read-only
system, and only the exercise’s files. Student code then cannot reach
your files, your network or the other students’ submissions either.
Build the image once from the file the package ships (add any package
the students or the tests use, because the container has no network):

``` bash
docker build -t corrector-runner "$(Rscript -e 'cat(system.file("container", package = "corrector"))')"
```

Each exercise takes a few seconds longer, because the container has to
start.

## Reading the notes

On every engine, corrector reads each student file before running it and
reports calls such as [`attach()`](https://rdrr.io/r/base/attach.html),
[`unlockBinding()`](https://rdrr.io/r/base/bindenv.html),
[`registerS3method()`](https://rdrr.io/r/base/ns-internal.html),
[`trace()`](https://rdrr.io/r/base/trace.html) or `parse(text = )`, and
writes into the global or base environment, as `suspicious code: ...` in
the `message` column. After the code runs, it reports what actually
changed (attached environments, registered S3 methods, replaced base
functions) as `tampering: ...`.
[`scan_code()`](https://anevolbap.github.io/corrector/reference/scan_code.md)
runs the first check on its own.

The notes do not change a test’s status.
[`grade_report()`](https://anevolbap.github.io/corrector/reference/grade_report.md)
lists the students who got one under “Check by hand”, so you can read
those files yourself:

``` r

grade_report(results)
#> ...
#> Check by hand (suspicious code or tampering, see the message column):
#>   Lopez
```

## Tests that are hard to fool

These habits help on every engine. They stop the S3 method tricks even
on `callr` and `inproc`. They do not stop
[`attach()`](https://rdrr.io/r/base/attach.html) or replaced base
functions there (a student can attach a fake
[`identical()`](https://rdrr.io/r/base/identical.html) too); only the
isolated engine stops those.

Compare with [`identical()`](https://rdrr.io/r/base/identical.html). It
does not dispatch on the class of its arguments, and it compares the
class too, so a student object with its own `==` or
[`all.equal()`](https://rdrr.io/r/base/all.equal.html) method does not
pass:

``` r

test_ejercicio1_raices <- function() {
  identical(ceros_cuadratica(1, 0, -1), c(-1, 1))
}
```

For numbers that need a tolerance, check that the result is a plain
number before you compare it:

``` r

test_ejercicio1_media <- function() {
  x <- media(c(1, 2, 4))
  is.double(x) && !is.object(x) && isTRUE(all.equal(x, 7 / 3))
}
```

With testthat, prefer `expect_identical()` and `expect_type()`.

Use inputs the student cannot know in advance. A student who has seen
the tests can hard-code the answers; random inputs checked against a
reference solution in the test file stop that:

``` r

test_ejercicio2_ordenar <- function() {
  x <- sample(100, 20)
  identical(ordenar(x), sort(x))
}
```

## What is still possible

- Student code runs as your user, so it can read any file you can,
  including the test files and the reference solutions in them. It can
  also write any file you can, including corrector’s own temporary files
  and other students’ submissions, and start programs that outlive the
  grading. The isolated engine keeps student code out of the process
  that compares values, but it cannot stop attacks through the file
  system. The `"container"` engine does: inside the container the
  student only sees the files of their exercise. Still treat test files
  as visible to students, because the test is among those files.
- Inside the container, student code shares the folder where the test
  process leaves its result. A student who studies how corrector works
  could, in principle, forge their own result. The container protects
  your computer; it does not make cheating impossible for someone who
  studies the package.
- A student function returns whatever its author wants. If the tests use
  fixed inputs, an answer table works; random inputs stop that.
- The checks above look for known tricks. Obfuscated code that hides
  them usually shows up as `suspicious code` (for example a call to
  `parse(text = )` or a suspicious name inside a string), but not
  always.

corrector is not a sandbox. The [security
notes](https://anevolbap.github.io/corrector/#security) in the README
say more.
