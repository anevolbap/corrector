#' Export grading results to a CSV file
#'
#' @param results Data frame returned by [grade_submissions()].
#' @param path Output file path (e.g. `"grades.csv"`).
#' @return `results`, invisibly.
#' @importFrom utils write.csv
#' @export
export_to_csv <- function(results, path) {
  utils::write.csv(results, path, row.names = FALSE)
  invisible(results)
}

#' Export grading results to a Google Sheet
#'
#' Writes the results data frame to an existing Google Sheet, replacing its
#' contents. Requires the \pkg{googlesheets4} package and prior authentication —
#' call [googlesheets4::gs4_auth()] once per session before using this function.
#'
#' @param results Data frame returned by [grade_submissions()].
#' @param sheet_url URL of the target Google Sheet.
#' @param sheet Name or index of the worksheet tab (default: first sheet).
#' @return `results`, invisibly.
#' @export
export_to_sheets <- function(results, sheet_url, sheet = 1) {
  if (!requireNamespace("googlesheets4", quietly = TRUE)) {
    stop(
      "Package 'googlesheets4' is required. ",
      "Install with: install.packages('googlesheets4')"
    )
  }
  googlesheets4::sheet_write(results, ss = sheet_url, sheet = sheet)
  invisible(results)
}

#' Export grading results to an HTML report
#'
#' Produces a self-contained HTML file with a colour-coded table (green = pass,
#' red = fail), a per-student score column, and a pass-rate summary row.
#' No extra packages required.
#'
#' @param results Data frame returned by [grade_submissions()].
#' @param path Output file path (e.g. `"report.html"`).
#' @return `results`, invisibly.
#' @export
export_to_html <- function(results, path) {
  exercise_cols <- setdiff(names(results), "student")

  pass_rate <- colMeans(results[exercise_cols], na.rm = TRUE)
  student_scores <- rowMeans(results[exercise_cols], na.rm = TRUE)

  header_cells <- paste(
    c('<th>Student</th>',
      sprintf('<th>%s</th>', html_escape(exercise_cols)),
      '<th>Score</th>'),
    collapse = ""
  )

  body_rows <- vapply(seq_len(nrow(results)), function(i) {
    cells <- paste(
      vapply(results[i, exercise_cols, drop = FALSE], result_cell, character(1)),
      collapse = ""
    )
    sprintf('<tr><td>%s</td>%s<td class="score">%.0f%%</td></tr>',
            html_escape(results$student[[i]]), cells, student_scores[[i]] * 100)
  }, character(1))

  rate_cells <- paste(
    vapply(pass_rate, function(r) sprintf('<td class="score">%.0f%%</td>', r * 100), character(1)),
    collapse = ""
  )
  summary_row <- sprintf(
    '<tr class="summary"><td><strong>Pass rate</strong></td>%s<td class="score">%.0f%%</td></tr>',
    rate_cells, mean(student_scores, na.rm = TRUE) * 100
  )

  html <- paste0(
    '<!DOCTYPE html><html><head><meta charset="UTF-8">',
    '<title>Grade Report</title><style>',
    'body{font-family:sans-serif;margin:2em}',
    'table{border-collapse:collapse}',
    'th,td{border:1px solid #ccc;padding:8px 14px;text-align:center}',
    'th{background:#f0f0f0}',
    'td:first-child{text-align:left}',
    '.pass{background:#d4edda}',
    '.fail{background:#f8d7da}',
    '.score{background:#fff3cd;font-weight:bold}',
    '.summary{background:#e9ecef;font-style:italic}',
    '</style></head><body>',
    '<h1>Grade Report</h1><table>',
    '<thead><tr>', header_cells, '</tr></thead><tbody>',
    paste(body_rows, collapse = ""),
    summary_row,
    '</tbody></table></body></html>'
  )

  writeLines(html, path)
  invisible(results)
}

# ---------- internal helpers ----------

result_cell <- function(value) {
  if (isTRUE(value[[1]])) '<td class="pass">&#10003;</td>'
  else if (isFALSE(value[[1]])) '<td class="fail">&#10007;</td>'
  else '<td>&#8212;</td>'
}

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}
