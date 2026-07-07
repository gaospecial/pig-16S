figure_notes <- NULL

load_figure_notes <- function(path = "data/figure-notes.json") {
  if (is.null(figure_notes)) {
    figure_notes <<- jsonlite::fromJSON(path, simplifyVector = FALSE)
  }
  figure_notes
}

render_figure_note <- function(label) {
  notes <- load_figure_notes()
  note <- notes[[label]]
  if (is.null(note)) {
    return(invisible(NULL))
  }

  cat("\n\n::: {.callout-note appearance=\"simple\"}\n")
  cat("**图注：** ", note$caption, "\n\n", sep = "")
  cat("**Legend：** ", note$legend, "\n\n", sep = "")
  cat("**结果说明：** ", note$result, "\n", sep = "")
  cat(":::\n\n")
}
