#' Export grading results to a CSV file
#'
#' @param results A [grade_results] object.
#' @param path Output file path (e.g. `"grades.csv"`).
#' @param format `"wide"` (default) writes one row per student with one logical
#'   column per exercise. `"long"` writes the per-test detail.
#' @return `results`, invisibly.
#' @importFrom utils write.csv
#' @export
export_to_csv <- function(results, path, format = c("wide", "long")) {
  results <- ensure_grade_results(results)
  format <- match.arg(format)
  utils::write.csv(as.data.frame(results, format = format), path, row.names = FALSE)
  invisible(results)
}

#' Export grading results to a Google Sheet
#'
#' Writes results to an existing Google Sheet, replacing its contents. Requires
#' the \pkg{googlesheets4} package and prior authentication; call
#' `googlesheets4::gs4_auth()` once per session before using this function.
#'
#' @param results A [grade_results] object.
#' @param sheet_url URL of the target Google Sheet.
#' @param sheet Name or index of the worksheet tab (default: first sheet).
#' @param format `"wide"` (default) or `"long"`.
#' @return `results`, invisibly.
#' @export
export_to_sheets <- function(results, sheet_url, sheet = 1, format = c("wide", "long")) {
  results <- ensure_grade_results(results)
  format <- match.arg(format)
  if (!requireNamespace("googlesheets4", quietly = TRUE)) {
    stop(
      "Package 'googlesheets4' is required. ",
      "Install with: install.packages('googlesheets4')"
    )
  }
  googlesheets4::sheet_write(
    as.data.frame(results, format = format),
    ss    = sheet_url,
    sheet = sheet
  )
  invisible(results)
}

#' Export grading results to an HTML report
#'
#' Produces a self-contained HTML file with a colour-coded table (green = pass,
#' red = fail, amber = error/timeout, grey = missing), per-student score
#' column, and a pass-rate summary row.
#'
#' @param results A [grade_results] object.
#' @param path Output file path (e.g. `"report.html"`).
#' @param include_details If `TRUE`, append a per-test breakdown under each
#'   student (errors and timeouts include the message). Default `TRUE`.
#' @return `results`, invisibly.
#' @export
export_to_html <- function(results, path, include_details = TRUE) {
  results <- ensure_grade_results(results)
  wide <- as.data.frame(results, format = "wide")
  exercise_cols <- setdiff(names(wide), "student")

  pass_rate <- vapply(exercise_cols, function(ex) mean(wide[[ex]], na.rm = TRUE), numeric(1))
  student_scores <- vapply(seq_len(nrow(wide)), function(i) {
    mean(unlist(wide[i, exercise_cols, drop = FALSE]), na.rm = TRUE)
  }, numeric(1))

  header_cells <- paste(
    c('<th>Student</th>',
      sprintf('<th>%s</th>', html_escape(exercise_cols)),
      '<th>Score</th>'),
    collapse = ""
  )

  body_rows <- vapply(seq_len(nrow(wide)), function(i) {
    student <- wide$student[[i]]
    cells <- paste(
      vapply(exercise_cols, function(ex) {
        rows <- results[results$student == student & results$exercise == ex, , drop = FALSE]
        status_cell(rows)
      }, character(1)),
      collapse = ""
    )
    score_pct <- if (is.nan(student_scores[[i]])) "&mdash;" else sprintf("%.0f%%", student_scores[[i]] * 100)
    row_html <- sprintf('<tr><td>%s</td>%s<td class="score">%s</td></tr>',
                        html_escape(student), cells, score_pct)
    if (include_details) {
      row_html <- paste0(row_html, details_row(results, student, length(exercise_cols) + 2))
    }
    row_html
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
    '.error{background:#fff3cd}',
    '.timeout{background:#ffe5b4}',
    '.missing{background:#e9ecef}',
    '.score{background:#fff3cd;font-weight:bold}',
    '.summary{background:#e9ecef;font-style:italic}',
    '.details{background:#fafafa;font-size:0.9em;text-align:left}',
    '.details ul{margin:0;padding-left:1.2em}',
    '</style></head><body>',
    '<h1>Grade Report</h1>',
    sprintf('<p>Generated %s</p>', format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
    '<table>',
    '<thead><tr>', header_cells, '</tr></thead><tbody>',
    paste(body_rows, collapse = ""),
    summary_row,
    '</tbody></table></body></html>'
  )

  writeLines(html, path)
  invisible(results)
}

# ---------- internal helpers ----------

status_cell <- function(rows) {
  if (nrow(rows) == 0) return('<td>&mdash;</td>')
  statuses <- as.character(rows$status)
  if ("source_error" %in% statuses) {
    return('<td class="error" title="source error">&#9888;</td>')
  }
  if ("missing" %in% statuses) {
    return('<td class="missing">&mdash;</td>')
  }
  if ("timeout" %in% statuses) {
    return('<td class="timeout">&#9203;</td>')
  }
  if ("error" %in% statuses) {
    return('<td class="error">&#9888;</td>')
  }
  if (all(statuses == "pass")) {
    return('<td class="pass">&#10003;</td>')
  }
  '<td class="fail">&#10007;</td>'
}

details_row <- function(results, student, ncols) {
  rows <- results[results$student == student, , drop = FALSE]
  if (nrow(rows) == 0) return("")
  items <- vapply(seq_len(nrow(rows)), function(i) {
    test  <- if (is.na(rows$test[[i]])) rows$exercise[[i]] else rows$test[[i]]
    label <- sprintf("%s.%s", rows$exercise[[i]], test)
    msg   <- if (!is.na(rows$message[[i]])) sprintf(" &mdash; %s", html_escape(rows$message[[i]])) else ""
    sprintf('<li><code>%s</code>: <span class="%s">%s</span>%s</li>',
            html_escape(label),
            as.character(rows$status[[i]]),
            as.character(rows$status[[i]]),
            msg)
  }, character(1))
  sprintf('<tr class="details"><td colspan="%d"><ul>%s</ul></td></tr>',
          ncols, paste(items, collapse = ""))
}

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x
}
