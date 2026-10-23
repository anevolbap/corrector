#' Pasar puntajes a una escala de notas
#'
#' Convierte puntajes entre 0 y 1 (por ejemplo `student_scores()$total`) en
#' notas. La escala es lineal en dos tramos: de 0 a `pass_at` la nota va de
#' `min` a `pass`, y de `pass_at` a 1 va de `pass` a `max`. Con los valores
#' por defecto es una escala de 1 a 10 donde el 60% es un 4. El redondeo nunca
#' sube a la nota de aprobación un puntaje menor que `pass_at`.
#'
#' @section English:
#' **Map scores to a grade scale.** Turns scores between 0 and 1 (for example
#' `student_scores()$total`) into grades. The scale is linear in two parts:
#' from 0 to `pass_at` the grade goes from `min` to `pass`, and from `pass_at`
#' to 1 it goes from `pass` to `max`. With the defaults it is a 1-10 scale
#' where 60% is a 4. Rounding never lifts a score below `pass_at` to the pass
#' mark.
#'
#' @param x Vector numérico de puntajes entre 0 y 1. Los `NA` se mantienen.
#'   *English:* Numeric vector of scores between 0 and 1. `NA` stays `NA`.
#' @param min,max Nota más baja y más alta de la escala.
#'   *English:* Lowest and highest grade on the scale.
#' @param pass Nota de aprobación.
#'   *English:* Pass mark.
#' @param pass_at Puntaje (entre 0 y 1) que corresponde a la nota de
#'   aprobación.
#'   *English:* Score (between 0 and 1) that earns the pass mark.
#' @param digits Cantidad de decimales de la nota.
#'   *English:* Number of decimal places in the grade.
#' @return Vector numérico de notas, del mismo largo que `x`.
#'   *English:* Numeric vector of grades, the same length as `x`.
#' @export
#' @examples
#' grade_scale(c(0, 0.5, 0.6, 0.85, 1))
#' notas <- student_scores(example_results())
#' notas$nota <- grade_scale(notas$total)
#' notas[, c("student", "total", "nota")]
grade_scale <- function(x, min = 1, max = 10, pass = 4, pass_at = 0.6, digits = 0) {
  if (!is.numeric(x) || any(x < 0 | x > 1, na.rm = TRUE)) {
    stop("x must hold scores between 0 and 1", call. = FALSE)
  }
  if (!(min < pass && pass < max)) {
    stop("pass must be between min and max", call. = FALSE)
  }
  if (!(pass_at > 0 && pass_at < 1)) {
    stop("pass_at must be between 0 and 1 (not included)", call. = FALSE)
  }
  low <- !is.na(x) & x < pass_at
  raw <- ifelse(low,
                min + (pass - min) * x / pass_at,
                pass + (max - pass) * (x - pass_at) / (1 - pass_at))
  grade <- round(raw, digits)
  # A failing score must stay below the pass mark after rounding.
  step <- 10^-digits
  grade[low & grade >= pass] <- round(pass - step, digits)
  grade
}
