# corrector

[Versión en español](README.md)

An R package for automatically grading student coding exercises. Each student
submits one R file per exercise; the professor provides matching test files. The
package sources both into an isolated environment, runs the tests, and returns
a per-test results object.

## Installation

```r
# install.packages("remotes")
remotes::install_github("anevolbap/corrector")
```

## Minimal end-to-end example

```r
library(corrector)

# --- 1. Create a fake submission folder ---
dir.create("submissions/garcia", recursive = TRUE)
dir.create("submissions/lopez",  recursive = TRUE)
dir.create("tests")

writeLines(
  'ceros_cuadratica <- function(a, b, c) {
     d <- b^2 - 4*a*c
     c((-b - sqrt(d)) / (2*a), (-b + sqrt(d)) / (2*a))
   }',
  "submissions/garcia/ejercicio1.R"
)

writeLines(
  'ceros_cuadratica <- function(a, b, c) c(0, 0)',  # wrong
  "submissions/lopez/ejercicio1.R"
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

# --- 2. Grade ---
results <- grade_submissions("submissions/", test_dir = "tests/")
results
# <grade_results> 4 rows, 2 students, 1 exercises
# Status:
#   pass  2
#   fail  2

# --- 3. Summarise and export ---
grade_report(results)
export_to_html(results, "report.html")
export_to_csv(results,  "grades.csv")
```

A built-in sample dataset is available to try the package immediately:

```r
results <- example_results()  # 8 fake students, 5 exercises
grade_report(results)
plot_report(results)
```

## Results shape

`grade_submissions()` and `grade_exercise()` return a `grade_results` object, a
long-format data frame with one row per (student, exercise, test):

| student | exercise   | test                    | status | message | duration |
|---------|------------|-------------------------|--------|---------|----------|
| Garcia  | ejercicio1 | test_ejercicio1_raices  | pass   | NA      | 0.001    |
| Lopez   | ejercicio1 | test_ejercicio1_raices  | fail   | NA      | 0.001    |

`status` is a factor with levels `pass`, `fail`, `error`, `timeout`, `missing`,
`source_error`. This makes it easy to tell a test that returned `FALSE` apart
from one that errored, hit a timeout, or a file the student never submitted.

The legacy wide view (one row per student, one logical column per exercise) is
one call away:

```r
as.data.frame(results, format = "wide")
#   student    ejercicio1
# 1 Garcia          TRUE
# 2 Lopez          FALSE
```

`NA` means the exercise was missing or failed to parse.

## How it works

The grader follows a naming convention:

```
submissions/
├── garcia_juan/
│   ├── ejercicio1.R   <- student file
│   └── ejercicio2.R
└── lopez_maria/
    ├── ejercicio1.R
    └── ejercicio2.R

tests/
├── test_ejercicio1.R  <- professor test file (name must match)
└── test_ejercicio2.R
```

Each test file contains functions named `test_<exercise>_<case>` that return
`TRUE` or `FALSE`:

```r
# tests/test_ejercicio1.R
test_ejercicio1_positivos <- function() {
  all(ceros_cuadratica(1, 0, -1) == c(-1, 1))
}

test_ejercicio1_tipo <- function() {
  is.numeric(ceros_cuadratica(1, 0, -1))
}
```

The expected exercise list comes from the test directory: every `test_*.R`
file defines an exercise. If a student does not submit an exercise that has a
test file, a row with `status = missing` is recorded rather than silently
skipping it.

Student code and test code are sourced into a fresh, isolated environment for
each exercise, so submissions cannot interfere with each other.

## Usage

```r
library(corrector)

# Grade a full batch (directory or .zip)
results <- grade_submissions("submissions/", test_dir = "tests/")

# Grade a single file during development
grade_exercise("submissions/garcia_juan/ejercicio1.R", test_dir = "tests/")

# Console summary
grade_report(results)

# Export
export_to_csv(results, "grades.csv")               # wide view by default
export_to_csv(results, "grades-long.csv", format = "long")
export_to_html(results, "report.html")             # colour-coded, per-test breakdown

# Export to Google Sheets (requires googlesheets4)
googlesheets4::gs4_auth()
export_to_sheets(results, "https://docs.google.com/spreadsheets/d/...")
```

## Plots

`plot_report()` produces three sequential plots: student scores ranked,
pass rate per exercise, and a pass/fail heatmap.

```r
# Interactive, pauses between plots
plot_report(results)

# Save to PDF
pdf("report.pdf", width = 8, height = 5)
plot_report(results, ask = FALSE)
dev.off()

# Use ggplot2 when installed (falls back to base R otherwise)
plot_report(results, backend = "ggplot2")
```

![Plots preview](man/figures/plots-preview.png)

## Timeout

```r
results <- grade_submissions("submissions/", test_dir = "tests/", timeout = 10)
```

By default the grader uses `setTimeLimit()` inside the current session. It
handles ordinary cases but does not always interrupt `Sys.sleep()` or every
tight loop. For a real wall-clock kill, use the `callr` engine:

```r
results <- grade_submissions(
  "submissions/", test_dir = "tests/",
  timeout = 10, engine = "callr"
)
```

`callr` runs each exercise in a fresh subprocess and kills it when the budget
is exceeded. Requires the `callr` package.

## Example test files

```r
system.file("examples", package = "corrector")
```

## Alternatives

- **[gradethis](https://pkgs.rstudio.com/gradethis/)**: grades code inside
  interactive [learnr](https://rstudio.github.io/learnr/) tutorials. Requires a
  Shiny server.
- **[exams](https://www.r-exams.org/)**: generates randomised exam questions,
  exports to Moodle, Canvas, PDF and more.
- **[RTutor](https://github.com/skranz/RTutor)**: Shiny-based interactive
  problem sets with automatic solution checking.

corrector is the lightest option: no server, plain `.R` file submissions,
zero hard dependencies.

## Folder names

The default extractor takes the first underscore-separated token of the folder
name and applies title case (so `garcia_juan_12345` becomes `Garcia`). Pass
`student_name_fn` to override:

```r
results <- grade_submissions(
  "submissions/", test_dir = "tests/",
  student_name_fn = function(folder) sub("_.*$", "", folder)
)
```

Submissions can also be handed in as a single `.zip`; the package extracts it
into a temporary directory before grading.

## Contributing

Feedback is welcome. Open an issue on GitHub.
