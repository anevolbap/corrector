# Checks against cheating that name filtering cannot stop. They report what
# they find in the message column; they do not change a test's status.

# Calls that change how other code behaves. Students rarely need them.
suspicious_calls <- c(
  "attach", "detach", "unlockBinding", "lockBinding", "assignInNamespace",
  "assignInMyNamespace", "registerS3method", "trace", "untrace",
  "setMethod", "setGeneric", "setReplaceMethod", "makeActiveBinding",
  "unloadNamespace", "sys.function", "reg.finalizer"
)

# Environments a student has no reason to write into.
outside_envs <- "globalenv|\\.GlobalEnv|baseenv|topenv|asNamespace|getNamespace|emptyenv|parent\\.env|parent\\.frame|sys\\.frame"

# S3 methods for the generics that tests use to compare values. Student
# objects with these names are not copied into the test environment.
comparison_methods <- "^(Ops|==|!=|<|>|<=|>=|all\\.equal|as\\.logical|isTRUE|identical)\\."

#' Find suspicious code in a student file
#'
#' Looks for calls that change how other code behaves (`attach()`,
#' `unlockBinding()`, `registerS3method()`, `trace()`, `setMethod()` and
#' similar), writes into the global or base environment, code built from
#' strings with `parse(text = )`, and replacement of a function's body or
#' environment. [grade_exercise()] runs it on every submission and puts the
#' findings in the `message` column as "suspicious code: ...". The code is
#' only read, never run.
#'
#' @param path Path to an R file.
#' @return Character vector of findings such as `"attach() at line 3"`;
#'   empty when nothing is found or the file does not parse.
#' @export
#' @examples
#' file <- tempfile(fileext = ".R")
#' writeLines(c("f <- function(x) x", 'attach(list(isTRUE = function(x) TRUE))'), file)
#' scan_code(file)
scan_code <- function(path) {
  lines <- iconv(readLines(path, warn = FALSE), from = source_encoding(path),
                 to = "UTF-8", sub = "?")
  exprs <- tryCatch(parse(text = lines, keep.source = TRUE),
                    error = function(e) NULL)
  if (is.null(exprs)) return(character())
  pd <- utils::getParseData(exprs)
  if (is.null(pd) || nrow(pd) == 0) return(character())
  found <- character()

  calls <- pd[pd$token == "SYMBOL_FUNCTION_CALL", ]
  hit <- calls[calls$text %in% suspicious_calls, ]
  found <- c(found, sprintf("%s() at line %d", hit$text, hit$line1))

  # The same names given as strings, e.g. get("attach") or do.call("attach").
  strings <- pd[pd$token == "STR_CONST", ]
  bare <- gsub("^[\"']|[\"']$", "", strings$text)
  hit <- strings[bare %in% suspicious_calls, ]
  found <- c(found, sprintf("\"%s\" as a string at line %d",
                            gsub("^[\"']|[\"']$", "", hit$text), hit$line1))

  # Writes into another environment, and code built from strings.
  call_text <- function(id) {
    # SYMBOL_FUNCTION_CALL -> expr (the name) -> expr (the whole call)
    utils::getParseText(pd, pd$parent[pd$id == pd$parent[pd$id == id]])
  }
  for (i in which(calls$text %in% c("assign", "delayedAssign", "eval", "evalq",
                                    "local", "rm", "sys.source"))) {
    txt <- call_text(calls$id[[i]])
    env <- regmatches(txt, regexpr(outside_envs, txt))
    if (length(env) == 1) {
      found <- c(found, sprintf("%s() into %s at line %d", calls$text[[i]],
                                sub("^\\.", "", env), calls$line1[[i]]))
    }
  }
  for (i in which(calls$text == "parse")) {
    if (grepl("\\btext\\s*=", call_text(calls$id[[i]]))) {
      found <- c(found, sprintf("parse(text = ) at line %d", calls$line1[[i]]))
    }
  }

  repl <- grep("\\b(body|formals|environment)\\s*\\([^)]*\\)\\s*(<-|=)", lines)
  found <- c(found, sprintf("replaces a function's %s at line %d",
                            sub(".*\\b(body|formals|environment)\\s*\\(.*", "\\1", lines[repl]),
                            repl))
  unique(found)
}

# Snapshot of what student code could change in a running R process. Only
# base R is used, so the function can run inside a callr subprocess.
integrity_snapshot <- function() {
  watch <- c("==", "!=", "<", ">", "<=", ">=", "!", "&", "|", "&&", "||",
             "isTRUE", "isFALSE", "identical", "all.equal", "all", "any",
             "is.numeric", "is.character", "is.logical", "length", "inherits",
             "class", "stopifnot", "tryCatch")
  table <- get(".__S3MethodsTable__.", envir = baseenv())
  list(search = search(), s3 = ls(table, all.names = TRUE),
       fns = mget(watch, envir = baseenv()))
}

# What changed since `snap`. Attached real packages and S3 methods that
# packages register are left out, so library() calls are not reported.
integrity_changes <- function(snap) {
  out <- character()
  new <- setdiff(search(), snap$search)
  is_package <- vapply(new, function(nm) {
    startsWith(nm, "package:") && isNamespaceLoaded(sub("^package:", "", nm))
  }, logical(1))
  if (any(!is_package)) {
    out <- c(out, paste("attached", paste(new[!is_package], collapse = ", ")))
  }
  table <- get(".__S3MethodsTable__.", envir = baseenv())
  s3 <- setdiff(ls(table, all.names = TRUE), snap$s3)
  from_package <- vapply(s3, function(nm) {
    f <- get(nm, envir = table)
    is.function(f) && !is.null(environment(f)) && isNamespace(environment(f))
  }, logical(1))
  if (any(!from_package)) {
    out <- c(out, paste("registered S3 methods", paste(s3[!from_package], collapse = ", ")))
  }
  now <- mget(names(snap$fns), envir = baseenv())
  # vapply(), not mapply(): mapply() calls isFALSE(), which student code
  # may have replaced.
  changed <- names(snap$fns)[!vapply(names(snap$fns), function(nm) {
    identical(snap$fns[[nm]], now[[nm]])
  }, logical(1))]
  if (length(changed) > 0) {
    out <- c(out, paste("changed base functions", paste(changed, collapse = ", ")))
  }
  out
}

# Undo what integrity_changes() reports, so one student's changes do not
# reach the next one (inproc engine). Replaced base functions cannot be put
# back safely, so they only get a warning.
integrity_restore <- function(snap) {
  for (nm in rev(setdiff(search(), snap$search))) {
    is_package <- startsWith(nm, "package:") &&
      isNamespaceLoaded(sub("^package:", "", nm))
    if (!is_package) detach(nm, character.only = TRUE)
  }
  table <- get(".__S3MethodsTable__.", envir = baseenv())
  for (nm in setdiff(ls(table, all.names = TRUE), snap$s3)) {
    f <- get(nm, envir = table)
    if (!(is.function(f) && !is.null(environment(f)) && isNamespace(environment(f)))) {
      rm(list = nm, envir = table)
    }
  }
  now <- mget(names(snap$fns), envir = baseenv())
  # vapply(), not mapply(): mapply() calls isFALSE(), which student code
  # may have replaced.
  changed <- names(snap$fns)[!vapply(names(snap$fns), function(nm) {
    identical(snap$fns[[nm]], now[[nm]])
  }, logical(1))]
  if (length(changed) > 0) {
    warning("Student code replaced base functions in this R session: ",
            paste(changed, collapse = ", "),
            ". Restart R before grading more, or use engine = \"callr\".",
            call. = FALSE)
  }
}

# Copies of the helpers above whose environment is base R, so callr can send
# them to a subprocess where corrector may not be installed.
portable <- function(f) {
  environment(f) <- baseenv()
  f
}

# What callr runs in a subprocess. callr gives the function it runs the
# global environment, where names can be masked by attach() in student code,
# so the real code arrives as `.f`, which keeps its base environment.
run_in_child <- function(.f, ...) .f(...)
