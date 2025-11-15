#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: genespace_counts_from_rds.R /path/to/genespace_input [ACCESSION]")

gsdir <- normalizePath(args[1], mustWork = TRUE)
acc   <- if (length(args) >= 2) args[2] else "Athaliana"

cat("[INFO] GENESPACE dir:", gsdir, "\n")
cat("[INFO] Accession of interest:", acc, "\n")

rds_path <- file.path(gsdir, "pangenome_matrix.rds")
if (!file.exists(rds_path)) {
  stop("Cannot find pangenome_matrix.rds in ", gsdir)
}

pam <- readRDS(rds_path)
pam <- as.data.frame(pam)

cat("[INFO] Pangenes table:", nrow(pam), "rows x", ncol(pam), "cols\n")
cat("[INFO] Columns (first 20):", paste(head(colnames(pam), 20), collapse = ", "), "\n")

## ----- 1) Identify orthogroup + genome columns -----
meta_cols <- c("pgID", "interpChr", "interpOrd", "og", "orthogroup",
               "repGene", "genome", "chr", "start", "end")

if ("orthogroup" %in% colnames(pam)) {
  # OK
} else if ("og" %in% colnames(pam)) {
  colnames(pam)[colnames(pam) == "og"] <- "orthogroup"
} else {
  stop("Could not find an orthogroup column ('og' or 'orthogroup').")
}

genome_cols <- setdiff(colnames(pam), meta_cols)
genome_cols <- genome_cols[genome_cols %in% colnames(pam)]

if (length(genome_cols) == 0) {
  stop("No genome columns detected.")
}

cat("[INFO] Genome columns:", paste(genome_cols, collapse = ", "), "\n")

if (!(acc %in% genome_cols)) {
  stop("Accession ", acc, " not found among genome columns.")
}

## ----- 2) Build presence/absence matrix -----
# presence = TRUE if the pangene has at least one gene for that genome
presenceMat_list <- lapply(genome_cols, function(cc) {
  v <- pam[[cc]]
  vapply(
    v,
    function(x) {
      if (is.null(x) || length(x) == 0 || all(is.na(x))) {
        FALSE
      } else {
        TRUE
      }
    },
    logical(1)
  )
})

presenceMat <- do.call(cbind, presenceMat_list)
colnames(presenceMat) <- genome_cols
rownames(presenceMat) <- pam$orthogroup

nGenomes      <- ncol(presenceMat)
rowPresCounts <- rowSums(presenceMat)

## ----- 3) Define core & accession-specific orthogroups -----
core_idx     <- which(rowPresCounts == nGenomes)
acc_spec_idx <- which(rowPresCounts == 1 & presenceMat[, acc])

cat("[INFO] # core orthogroups:        ", length(core_idx), "\n")
cat("[INFO] # accession-specific OGs:  ", length(acc_spec_idx), "\n")

## ----- 4) Count genes in those OGs for this accession -----
count_genes_in_rows <- function(rows, colname) {
  if (length(rows) == 0) return(0L)
  v <- pam[[colname]][rows]
  sum(vapply(v, function(x) {
    if (is.null(x) || length(x) == 0) return(0L)
    # x is typically a vector of gene IDs; just count non-NA elements
    sum(!is.na(x))
  }, integer(1)))
}

genes_core   <- count_genes_in_rows(core_idx, acc)
genes_acc_sp <- count_genes_in_rows(acc_spec_idx, acc)

cat("========================================\n")
cat("Accession:", acc, "\n")
cat("Genes in CORE orthogroups:              ", genes_core, "\n")
cat("Genes in ACCESSION-SPECIFIC orthogroups:", genes_acc_sp, "\n")
cat("========================================\n")
