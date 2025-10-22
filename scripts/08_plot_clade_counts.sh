#!/usr/bin/env bash
#SBATCH --job-name=plot_clades
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:20:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/plot_clades_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/plot_clades_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
OUTDIR="${WORKDIR}/results/TEsorter_all"
FIGDIR="${WORKDIR}/results/figures"
mkdir -p "${FIGDIR}"

# sanity checks
[[ -s "${OUTDIR}/Copia_clade_counts.tsv" ]] || { echo "[ERR] missing ${OUTDIR}/Copia_clade_counts.tsv"; exit 1; }
[[ -s "${OUTDIR}/Gypsy_clade_counts.tsv"  ]] || { echo "[ERR] missing ${OUTDIR}/Gypsy_clade_counts.tsv";  exit 1; }

# R setup
export R_LIBS_USER="${WORKDIR}/.Rlib"
module load R 2>/dev/null || true

Rscript - <<'RSCRIPT'
suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly=TRUE)) install.packages("data.table", repos="https://cloud.r-project.org")
  if (!requireNamespace("ggplot2",   quietly=TRUE)) install.packages("ggplot2",   repos="https://cloud.r-project.org")
  if (!requireNamespace("ragg",      quietly=TRUE)) install.packages("ragg",      repos="https://cloud.r-project.org")
})

library(data.table)
library(ggplot2)

workdir <- Sys.getenv("WORKDIR", unset="/data/users/mlawrence/eukaryote_genome_annotation")
outdir  <- file.path(workdir, "results/TEsorter_all")
figdir  <- file.path(workdir, "results/figures")

# read Copia & Gypsy clade counts
read_counts <- function(path, sf) {
  dt <- fread(path, sep="\t", header=TRUE)
  setnames(dt, c("Clade","Count"))
  dt[, Superfamily := sf]
  dt[is.na(Clade) | Clade=="", Clade := "Unclassified"]
  dt[is.na(Count), Count := 0L]
  dt
}

dc <- read_counts(file.path(outdir, "Copia_clade_counts.tsv"), "Copia")
dg <- read_counts(file.path(outdir, "Gypsy_clade_counts.tsv"),  "Gypsy")
d  <- rbindlist(list(dc, dg), use.names=TRUE, fill=TRUE)

# order clades by count within each superfamily
d[, Clade := factor(Clade, levels = d[order(Superfamily, -Count), unique(Clade)])]

p <- ggplot(d, aes(x = Count, y = Clade)) +
  geom_col() +
  facet_wrap(~ Superfamily, scales="free_y", ncol=1) +
  labs(
    title = "LTR-RT clade counts (TEsorter on final EDTA library)",
    x = "Elements (count)", y = "Clade"
  ) +
  theme_minimal(base_size = 12)

png_file <- file.path(figdir, "03_clade_counts.png")
pdf_file <- file.path(figdir, "03_clade_counts.pdf")

# write PDF (always headless-safe)
ggsave(pdf_file, p, width=8, height=10, units="in")

# write PNG using ragg (no X11 needed)
ragg::agg_png(png_file, width=8, height=10, units="in", res=120); print(p); dev.off()

cat("[OK] Wrote:", pdf_file, "and", png_file, "\n")
RSCRIPT
