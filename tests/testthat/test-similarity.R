make_similar <- function(envir = parent.frame()) {
  subs <- withr::local_tempdir(.local_envir = envir)
  write <- function(student, lines) {
    dir.create(file.path(subs, student), showWarnings = FALSE)
    writeLines(lines, file.path(subs, student, "ejercicio1.R"))
  }
  original <- c(
    "promedio <- function(x) {",
    "  total <- 0",
    "  for (v in x) total <- total + v",
    "  total / length(x)",
    "}"
  )
  # Same code with other names, spacing and comments.
  copy <- c(
    "# mi solucion",
    "promedio<-function(valores){",
    "  acumulado<-0   # empiezo en cero",
    "  for(elemento in valores) acumulado<-acumulado+elemento",
    "  acumulado/length(valores)",
    "}"
  )
  other <- c(
    "promedio <- function(x) {",
    "  if (length(x) == 0) return(NA_real_)",
    "  sum(x) / length(x)",
    "}"
  )
  write("ana", original)
  write("beto", copy)
  write("carla", other)
  subs
}

test_that("renamed, reformatted copies score as identical", {
  res <- compare_submissions(make_similar(), min_similarity = 0)
  ab <- res[res$student_a %in% c("Ana", "Beto") & res$student_b %in% c("Ana", "Beto"), ]
  expect_equal(ab$similarity, 1)
  ac <- res[res$student_a %in% c("Ana", "Carla") & res$student_b %in% c("Ana", "Carla"), ]
  expect_lt(ac$similarity, 0.5)
})

test_that("compare_submissions filters, sorts and names columns", {
  res <- compare_submissions(make_similar())
  expect_named(res, c("exercise", "student_a", "student_b", "similarity"))
  expect_equal(nrow(res), 1)
  expect_equal(res$exercise, "ejercicio1")
  all <- compare_submissions(make_similar(), min_similarity = 0)
  expect_equal(nrow(all), 3)
  expect_false(is.unsorted(rev(all$similarity)))
})

test_that("compare_submissions reads Rmd files and Moodle exports", {
  skip_if_not_installed("knitr")
  subs <- withr::local_tempdir()
  for (who in c("Ana Gomez_101", "Beto Diaz_102")) {
    d <- file.path(subs, paste0(who, "_assignsubmission_file"))
    dir.create(d)
    writeLines(c("```{r}", "sumar <- function(a, b) a + b", "```"),
               file.path(d, "Ejercicio1.Rmd"))
  }
  res <- compare_submissions(subs, layout = "moodle")
  expect_equal(nrow(res), 1)
  expect_setequal(c(res$student_a, res$student_b), c("Ana Gomez", "Beto Diaz"))
  expect_equal(res$similarity, 1)
})

test_that("files that do not parse are still compared", {
  subs <- withr::local_tempdir()
  for (s in c("ana", "beto")) {
    dir.create(file.path(subs, s))
    writeLines(c("sumar <- function(a, b) {", "  a + b"), file.path(subs, s, "ejercicio1.R"))
  }
  res <- compare_submissions(subs)
  expect_equal(res$similarity, 1)
})

test_that("compare_submissions returns no rows with fewer than two students", {
  subs <- withr::local_tempdir()
  dir.create(file.path(subs, "ana"))
  writeLines("x <- 1", file.path(subs, "ana", "ejercicio1.R"))
  res <- compare_submissions(subs)
  expect_equal(nrow(res), 0)
  expect_named(res, c("exercise", "student_a", "student_b", "similarity"))
})
