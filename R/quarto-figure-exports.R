enable_quarto_figure_exports <- function() {
  if (!requireNamespace("knitr", quietly = TRUE)) {
    return(invisible(FALSE))
  }

  knitr::opts_chunk$set(
    dev = "png",
    dpi = 300
  )

  knitr::opts_hooks$set(fig.cap = quarto_append_figure_download_links)
  invisible(TRUE)
}

quarto_append_figure_download_links <- function(options) {
  label <- options$label
  fig_cap <- options$fig.cap

  if (is.null(label) || !startsWith(label, "fig-") || is.null(fig_cap)) {
    return(options)
  }

  options$dev <- c("png", "pdf")
  download_links <- sprintf(" [PDF](%s)", quarto_figure_export_href(options, "pdf"))

  options$fig.cap <- paste0(fig_cap, download_links)
  options
}

quarto_figure_export_href <- function(options, extension) {
  fig_path <- options$fig.path %||% knitr::opts_chunk$get("fig.path") %||% "figure/"
  fig_path <- sub("^\\./", "", fig_path)
  fig_path <- gsub("\\\\", "/", fig_path)
  fig_path <- if (endsWith(fig_path, "/")) fig_path else paste0(fig_path, "/")

  paste0(fig_path, options$label, "-1.", extension)
}

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

if (identical(Sys.getenv("QUARTO_FIGURE_EXPORTS", "true"), "true")) {
  enable_quarto_figure_exports()
}
