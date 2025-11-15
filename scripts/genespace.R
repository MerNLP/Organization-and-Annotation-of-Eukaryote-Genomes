#!/usr/bin/env Rscript
suppressPackageStartupMessages({
  library(GENESPACE)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript scripts/genespace.R /path/to/genespace_input")
wd <- normalizePath(args[1], mustWork = TRUE)

cat("[INFO] GENESPACE working directory:", wd, "\n")

# --------------------------------------------------
# 1) Run GENESPACE
# --------------------------------------------------
gpar <- init_genespace(
  wd           = wd,
  path2mcscanx = "/usr/local/bin",
  nCores       = 20
)

cat("[INFO] GENESPACE genomes:", paste(gpar$genomeIDs, collapse = ", "), "\n")

out <- run_genespace(gpar, overwrite = TRUE)

# Save the full GENESPACE parameter object for debugging
saveRDS(out, file = file.path(wd, "genespace_out.rds"))

# --------------------------------------------------
# 2) Build pangenome matrix via query_pangenes
# --------------------------------------------------
pg <- query_pangenes(
  out,
  bed          = NULL,
  refGenome    = "TAIR10",
  transform    = TRUE,
  showArrayMem = TRUE,
  showNSOrtho  = TRUE,
  maxMem2Show  = Inf
)

saveRDS(pg, file = file.path(wd, "pangenome_matrix.rds"))

cat("[INFO] query_pangenes() returned object of class:",
    paste(class(pg), collapse = ", "), "\n")

# In this container, query_pangenes returns the pangene table itself
if (is.data.frame(pg) || "data.table" %in% class(pg)) {
  pam <- as.data.frame(pg)
} else if (!is.null(pg$pangenes)) {
  pam <- as.data.frame(pg$pangenes)
} else if (is.list(pg) && length(pg) > 0 && is.data.frame(pg[[1]])) {
  pam <- as.data.frame(pg[[1]])
} else {
  pam <- NULL
}

if (!is.null(pam)) {
  cat("[INFO] pangenes matrix dimensions:", paste(dim(pam), collapse = " x "), "\n")
  cat("[INFO] pangenes columns (first 20):",
      paste(head(colnames(pam), 20), collapse = ", "), "\n")
} else {
  cat("[WARN] could not interpret query_pangenes() output as a pangenes matrix.\n")
}

# --------------------------------------------------
# Helper: write zero summaries and quit
# --------------------------------------------------
write_zero_summaries_and_quit <- function(gpar, wd, reason = "") {
  if (nzchar(reason)) cat("[WARN]", reason, "\n")

  genomeIDs <- gpar$genomeIDs
  summ_by_acc <- data.frame(
    accession    = genomeIDs,
    genes_total  = 0L,
    genes_core   = 0L,
    genes_unique = 0L,
    genes_access = 0L,
    stringsAsFactors = FALSE
  )
  
  og_summary <- data.frame(
    category = c("core_orthogroups","accessory_orthogroups","unique_orthogroups"),
    n        = c(0L, 0L, 0L),
    stringsAsFactors = FALSE
  )
  
  outdir <- file.path(wd, "genespace_results")
  dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
  
  write.table(
    summ_by_acc,
    file = file.path(outdir, "per_accession_core_accessory_unique_genes.tsv"),
    sep = "\t", quote = FALSE, row.names = FALSE
  )
  
  write.table(
    og_summary,
    file = file.path(outdir, "orthogroup_category_counts.tsv"),
    sep = "\t", quote = FALSE, row.names = FALSE
  )
  
  mine <- summ_by_acc[summ_by_acc$accession == "Athaliana", , drop = FALSE]
  write.table(
    mine,
    file = file.path(outdir, "Athaliana_core_accessory_unique_genes.tsv"),
    sep = "\t", quote = FALSE, row.names = FALSE
  )
  
  cat("[DONE] GENESPACE complete (no usable pangenes; wrote zeros).\n")
  quit(save = "no")
}

# --------------------------------------------------
# 2b) Check for empty / malformed pangenes
#      and detect orthogroup column
# --------------------------------------------------
if (is.null(pam) || nrow(pam) == 0 || ncol(pam) <= 1) {
  write_zero_summaries_and_quit(
    gpar,
    wd,
    reason = "pangenes matrix is NULL or has zero rows/columns."
  )
}

# Determine which column stores orthogroup IDs
og_col <- NULL
if ("orthogroup" %in% colnames(pam)) {
  og_col <- "orthogroup"
} else if ("og" %in% colnames(pam)) {
  og_col <- "og"
  # rename to 'orthogroup' internally for consistency
  colnames(pam)[colnames(pam) == "og"] <- "orthogroup"
} else {
  write_zero_summaries_and_quit(
    gpar,
    wd,
    reason = "Could not find an orthogroup column ('orthogroup' or 'og')."
  )
}

# --------------------------------------------------
# 3) Normal case: compute core/accessory/unique
# --------------------------------------------------
pam <- as.data.frame(pam)

# Genome columns should match gpar$genomeIDs
genome_cols <- gpar$genomeIDs
missing_cols <- setdiff(genome_cols, colnames(pam))
if (length(missing_cols) > 0) {
  write_zero_summaries_and_quit(
    gpar,
    wd,
    reason = paste("Missing genome columns in pangenes matrix:",
                   paste(missing_cols, collapse = ", "))
  )
}

pam_noOG <- pam[, genome_cols, drop = FALSE]

## Convert any list columns to plain integer 0/1 (or counts)
for (cc in genome_cols) {
  v <- pam_noOG[[cc]]
  
  if (is.list(v)) {
    # list of length-1 vectors -> pull first element; NULL/NA -> 0
    pam_noOG[[cc]] <- vapply(
      v,
      function(x) {
        if (length(x) == 0 || all(is.na(x))) {
          0L
        } else {
          as.integer(x[1])
        }
      },
      integer(1)
    )
  } else {
    # force to integer numeric, NA -> 0
    v[is.na(v)] <- 0
    pam_noOG[[cc]] <- as.integer(v)
  }
}

acc_names <- colnames(pam_noOG)

# presence matrix: pangene x genome
presenceMat <- pam_noOG > 0
nGenomes    <- ncol(pam_noOG)

# classify orthogroups (rows) by how many genomes have them
rowPresCounts <- rowSums(presenceMat)

core_og_idx   <- which(rowPresCounts == nGenomes)
access_og_idx <- which(rowPresCounts > 1 & rowPresCounts < nGenomes)
unique_og_idx <- which(rowPresCounts == 1)

cat("[INFO] # core orthogroups:     ", length(core_og_idx), "\n")
cat("[INFO] # accessory orthogroups:", length(access_og_idx), "\n")
cat("[INFO] # unique orthogroups:   ", length(unique_og_idx), "\n")

# per-genome gene counts
genes_total  <- colSums(presenceMat)
genes_core   <- colSums(presenceMat[core_og_idx, , drop = FALSE])
genes_unique <- colSums(presenceMat[unique_og_idx, , drop = FALSE])
genes_access <- colSums(presenceMat[access_og_idx, , drop = FALSE])

summ_by_acc <- data.frame(
  accession    = acc_names,
  genes_total  = as.integer(genes_total),
  genes_core   = as.integer(genes_core),
  genes_unique = as.integer(genes_unique),
  genes_access = as.integer(genes_access),
  stringsAsFactors = FALSE
)

og_summary <- data.frame(
  category = c("core_orthogroups","accessory_orthogroups","unique_orthogroups"),
  n        = c(length(core_og_idx), length(access_og_idx), length(unique_og_idx)),
  stringsAsFactors = FALSE
)

outdir <- file.path(wd, "genespace_results")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)

write.table(
  summ_by_acc,
  file = file.path(outdir, "per_accession_core_accessory_unique_genes.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)

write.table(
  og_summary,
  file = file.path(outdir, "orthogroup_category_counts.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)

mine <- summ_by_acc[summ_by_acc$accession == "Athaliana", , drop = FALSE]
write.table(
  mine,
  file = file.path(outdir, "Athaliana_core_accessory_unique_genes.tsv"),
  sep = "\t", quote = FALSE, row.names = FALSE
)

cat("[DONE] GENESPACE complete.\n")
