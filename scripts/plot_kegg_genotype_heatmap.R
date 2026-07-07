suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tibble)
  library(pheatmap)
  library(RColorBrewer)
  library(grid)
})

dir.create("figure", showWarnings = FALSE, recursive = TRUE)
dir.create("data/picrust2-result/derived", showWarnings = FALSE, recursive = TRUE)

ko_file <- "data/picrust2-result/picrust2_output/KO_metagenome_out/pred_metagenome_unstrat.tsv.gz"
sample_file <- "data/amplicon-sequencing/sample_table_mt.csv"
brite_url <- "https://rest.kegg.jp/get/br:ko00001"
brite_file <- "data/picrust2-result/derived/ko00001.keg"

if (!file.exists(brite_file)) {
  download.file(brite_url, brite_file, quiet = TRUE)
}

parse_ko_brite <- function(path) {
  lines <- readLines(path, warn = FALSE)
  current_b <- NA_character_
  out <- vector("list", length(lines))
  n <- 0L

  for (line in lines) {
    if (grepl("^B\\s+", line)) {
      current_b <- sub("^B\\s+\\d+\\s+", "", line)
    } else if (grepl("^D\\s+K\\d{5}", line) && !is.na(current_b)) {
      ko <- sub("^D\\s+(K\\d{5}).*$", "\\1", line)
      n <- n + 1L
      out[[n]] <- data.frame(ko = paste0("ko:", ko), kegg_class = current_b)
    }
  }

  bind_rows(out[seq_len(n)]) |>
    distinct(ko, kegg_class)
}

ko_map <- parse_ko_brite(brite_file)

sample_meta <- read_csv(sample_file, show_col_types = FALSE) |>
  rename(sample = 1) |>
  mutate(genotype = factor(genotype, levels = c("AA", "GA", "GG"))) |>
  filter(!is.na(genotype))

ko_abun <- read_tsv(ko_file, show_col_types = FALSE) |>
  rename(ko = 1)

sample_cols <- intersect(sample_meta$sample, colnames(ko_abun))

if (length(sample_cols) == 0) {
  stop("No overlapping samples between KO abundance table and sample metadata.")
}

class_by_sample <- ko_abun |>
  inner_join(ko_map, by = "ko", relationship = "many-to-many") |>
  select(kegg_class, all_of(sample_cols)) |>
  group_by(kegg_class) |>
  summarise(across(all_of(sample_cols), sum), .groups = "drop")

sample_totals <- colSums(as.matrix(class_by_sample[, sample_cols, drop = FALSE]))
class_rel <- class_by_sample
class_rel[, sample_cols] <- sweep(
  as.matrix(class_by_sample[, sample_cols, drop = FALSE]),
  2,
  sample_totals,
  "/"
) * 100

genotype_levels <- c("AA", "GA", "GG")
genotype_mat <- sapply(genotype_levels, function(g) {
  cols <- sample_meta |>
    filter(genotype == g, sample %in% sample_cols) |>
    pull(sample)
  rowMeans(as.matrix(class_rel[, cols, drop = FALSE]), na.rm = TRUE)
})

rownames(genotype_mat) <- class_rel$kegg_class
genotype_mat <- genotype_mat[rowSums(genotype_mat) > 0, , drop = FALSE]

scaled_mat <- t(scale(t(log10(genotype_mat + 1e-6))))
scaled_mat[is.na(scaled_mat)] <- 0
scaled_mat <- pmax(pmin(scaled_mat, 1), -1)

class_variation <- apply(scaled_mat, 1, sd)
class_variation[is.na(class_variation)] <- 0

class_summary <- as.data.frame(genotype_mat) |>
  rownames_to_column("kegg_class") |>
  mutate(
    class_variation = class_variation[kegg_class],
    direction_index = GG - AA
  ) |>
  arrange(desc(class_variation), desc(rowSums(across(all_of(genotype_levels)))))

write_csv(class_summary, "data/picrust2-result/derived/kegg_class_by_genotype.csv")

plot_classes <- head(class_summary$kegg_class, min(35, nrow(class_summary)))

plot_mat <- scaled_mat[plot_classes, genotype_levels, drop = FALSE]

heat_cols <- colorRampPalette(c("#0615A8", "white", "#E31A1C"))(101)
breaks <- seq(-1, 1, length.out = length(heat_cols) + 1)

draw_heatmap <- function(filename, width, height, device = c("png", "pdf")) {
  device <- match.arg(device)
  if (device == "png") {
    png(filename, width = width, height = height, units = "in", res = 320)
  } else {
    pdf(filename, width = width, height = height, useDingbats = FALSE)
  }
  on.exit(dev.off(), add = TRUE)

  pheatmap(
    plot_mat,
    color = heat_cols,
    breaks = breaks,
    cluster_rows = TRUE,
    cluster_cols = TRUE,
    border_color = "#8A8A8A",
    fontsize = 10,
    fontsize_row = 8.5,
    fontsize_col = 15,
    angle_col = 0,
    treeheight_row = 48,
    treeheight_col = 34,
    legend = TRUE,
    legend_breaks = c(-1, -0.5, 0, 0.5, 1),
    legend_labels = c("-1", "-0.5", "0", "0.5", "1"),
    main = "Heatmap of KEGG pathways for different genotypes",
    silent = FALSE
  )
}

draw_heatmap("figure/kegg_pathway_genotype_heatmap_pheatmap.png", 9.5, 7.6, "png")
draw_heatmap("figure/kegg_pathway_genotype_heatmap_pheatmap.pdf", 9.5, 7.6, "pdf")

message("Saved: figure/kegg_pathway_genotype_heatmap_pheatmap.png")
message("Saved: figure/kegg_pathway_genotype_heatmap_pheatmap.pdf")
message("Saved: data/picrust2-result/derived/kegg_class_by_genotype.csv")
