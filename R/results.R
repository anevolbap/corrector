#' Grading results object
#'
#' A `grade_results` object is a data frame in long format with one row per
#' (student, exercise, test) and the following columns:
#' \describe{
#'   \item{`student`}{Character. Student display name.}
#'   \item{`exercise`}{Character. Exercise identifier (file stem).}
#'   \item{`test`}{Character. Test function name, or `NA` when the row
#'     records a `missing` submission or a `source_error`.}
#'   \item{`status`}{Factor with levels `pass`, `fail`, `error`, `timeout`,
#'     `missing`, `source_error`.}
#'   \item{`message`}{Character. Error message when `status` is `error`,
#'     `source_error`, or `timeout`; `NA` otherwise.}
#'   \item{`duration`}{Numeric. Seconds elapsed running the test, or `NA`
#'     when the test was not run.}
#' }
#'
#' Use [as.data.frame()] with `format = "wide"` to get the old wide-boolean
#' view (one logical column per exercise, `TRUE` iff all tests passed).
#'
#' @name grade_results
NULL

status_levels <- c("pass", "fail", "error", "timeout", "missing", "source_error")

new_grade_results <- function(df) {
  stopifnot(is.data.frame(df))
  expected <- c("student", "exercise", "test", "status", "message", "duration")
  missing_cols <- setdiff(expected, names(df))
  if (length(missing_cols) > 0) {
    stop("grade_results is missing columns: ",
         paste(missing_cols, collapse = ", "))
  }
  df <- df[expected]
  if (!is.factor(df$status)) {
    df$status <- factor(df$status, levels = status_levels)
  }
  structure(df, class = c("grade_results", "data.frame"))
}

empty_grade_results <- function() {
  new_grade_results(data.frame(
    student  = character(),
    exercise = character(),
    test     = character(),
    status   = factor(character(), levels = status_levels),
    message  = character(),
    duration = numeric(),
    stringsAsFactors = FALSE
  ))
}

#' @export
print.grade_results <- function(x, ...) {
  cat(sprintf("<grade_results> %d rows, %d students, %d exercises\n",
              nrow(x),
              length(unique(x$student)),
              length(unique(x$exercise))))
  if (nrow(x) == 0) return(invisible(x))
  counts <- table(x$status)
  cat("Status:\n")
  for (lvl in names(counts)) {
    if (counts[[lvl]] > 0) {
      cat(sprintf("  %-13s %d\n", lvl, counts[[lvl]]))
    }
  }
  invisible(x)
}

#' Convert grading results to a data frame
#'
#' @param x A `grade_results` object.
#' @param row.names Ignored.
#' @param optional Ignored.
#' @param format `"long"` returns the underlying long-format data frame.
#'   `"wide"` returns the legacy view: one row per student, one logical column
#'   per exercise (`TRUE` iff all tests passed; `NA` for `missing` or
#'   `source_error`).
#' @param ... Ignored.
#' @return A plain data frame.
#' @export
as.data.frame.grade_results <- function(x, row.names = NULL, optional = FALSE,
                                        format = c("long", "wide"), ...) {
  format <- match.arg(format)
  long <- unclass(x)
  attr(long, "class") <- "data.frame"
  if (format == "long") return(long)

  students  <- unique(x$student)
  exercises <- unique(x$exercise)
  wide <- data.frame(student = students, stringsAsFactors = FALSE)
  for (ex in exercises) {
    wide[[ex]] <- vapply(students, function(st) {
      rows <- x[x$student == st & x$exercise == ex, , drop = FALSE]
      if (nrow(rows) == 0) return(NA)
      if (any(rows$status %in% c("missing", "source_error"))) return(NA)
      all(rows$status == "pass")
    }, logical(1))
  }
  wide
}
