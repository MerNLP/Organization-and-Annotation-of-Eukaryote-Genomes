#!/usr/bin/env bash
#SBATCH --job-name=circlize_TE
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=01:00:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/circlize_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/circlize_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
FIGDIR="${WORKDIR}/results/figures"
mkdir -p "${FIGDIR}"

# Inputs
GFF="${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3"
IDEO="${EDTA_OUT}/ideogram.tsv"   

# Params
export TOP_N=6         # top superfamilies to plot
export N_SCAFFOLDS=10  # longest scaffolds to plot
export WINDOW=100000   # density window size (bp)

# R libs
export R_LIBS_USER="${WORKDIR}/.Rlib"
module load R 2>/dev/null || true

Rscript - <<'RSCRIPT'
suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly=TRUE)) install.packages("data.table", repos="https://cloud.r-project.org")
  if (!requireNamespace("circlize",   quietly=TRUE)) install.packages("circlize",   repos="https://cloud.r-project.org")
})

library(data.table)
library(circlize)

workdir <- Sys.getenv("WORKDIR", unset="/data/users/mlawrence/eukaryote_genome_annotation")
edta    <- file.path(workdir, "results/EDTA_annotation")
figdir  <- file.path(workdir, "results/figures")
gff     <- file.path(edta, "hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3")
ideo    <- file.path(edta, "ideogram.tsv")
topN    <- as.integer(Sys.getenv("TOP_N", "6"))
nScaf   <- as.integer(Sys.getenv("N_SCAFFOLDS", "10"))
win     <- as.integer(Sys.getenv("WINDOW", "100000"))

stopifnot(file.exists(gff), file.exists(ideo))

# --- Read GFF robustly (strip comments) ---
all_lines  <- readLines(gff, warn=FALSE)
data_lines <- all_lines[!startsWith(all_lines, "#") & nzchar(all_lines)]
tmp <- tempfile(fileext=".gff3")
writeLines(data_lines, tmp)
dt <- fread(tmp, sep="\t", header=FALSE, fill=TRUE, data.table=TRUE, quote="")
unlink(tmp)

if (ncol(dt) < 9) stop("GFF has fewer than 9 columns after comment removal.")
dt <- dt[, 1:9]
setnames(dt, c("chr","src","type","start","end","score","strand","phase","attr"))

# Keep top-level TE features and parse Superfamily
dt <- dt[type %in% c("transposable_element","repeat_region")]
extract_attr <- function(s, key){
  m <- regexpr(paste0("(?<=", key, "=)[^;]+"), s, perl=TRUE)
  ifelse(m > 0, regmatches(s, m), NA_character_)
}
dt[, Superfamily := extract_attr(attr, "Superfamily")]
dt[, start := as.numeric(start)]
dt[, end   := as.numeric(end)]
dt <- dt[!is.na(Superfamily) & !is.na(start) & !is.na(end)]
dt <- dt[end >= start]

# Top superfamilies by covered bp
dt[, len := pmax(1, end - start + 1)]
top_sf <- dt[, .(bp = sum(len, na.rm=TRUE)), by=Superfamily][order(-bp)][1:min(topN, .N), Superfamily]
if (length(top_sf) == 0L) stop("No superfamilies found with Superfamily= attribute in final GFF3.")

# Tracks table
tracks <- dt[Superfamily %in% top_sf, .(chr, start, end, Superfamily)]

# Ideogram: keep N longest scaffolds
ideoDT <- fread(ideo, header=FALSE)
setnames(ideoDT, c("chr","start","end"))
ideoDT[, start := as.numeric(start)]
ideoDT[, end   := as.numeric(end)]
ideoDT <- ideoDT[order(-end)][1:min(nScaf, .N)]
tracks <- tracks[chr %in% ideoDT$chr]

# Small gap so total gaps < 360°
gap_val <- 0.5

draw_plot <- function() {
  circos.clear()
  circos.par(start.degree=90, gap.degree=gap_val, track.margin=c(0.01,0.01))
  circos.genomicInitialize(ideoDT)
  cols <- setNames(rainbow(length(top_sf)), top_sf)
  for (sf in top_sf) {
    seg_dt <- tracks[Superfamily == sf, .(chr, start, end)]
    if (nrow(seg_dt) == 0) next
    # Ensure plain data.frame with numeric start/end
    seg <- as.data.frame(seg_dt)
    seg$start <- as.numeric(seg$start)
    seg$end   <- as.numeric(seg$end)
    seg <- seg[seg$end >= seg$start, ]
    if (nrow(seg) == 0) next
    circos.genomicDensity(seg, col = cols[sf], track.height = 0.08, window.size = win)
  }
  circos.clear()
}

out_png <- file.path(figdir, "02_TE_density_circlize.png")
out_pdf <- file.path(figdir, "02_TE_density_circlize.pdf")

# Always write PDF (headless-safe)
pdf(out_pdf, width=12, height=8); draw_plot(); dev.off()

# PNG: Cairo if available, else ragg (no X11)
png_ok <- FALSE
if (capabilities("cairo")) {
  try({
    png(out_png, width=1400, height=900, res=120, units="px", type="cairo")
    draw_plot(); dev.off(); png_ok <- TRUE
  }, silent=TRUE)
}
if (!png_ok) {
  if (!requireNamespace("ragg", quietly=TRUE)) install.packages("ragg", repos="https://cloud.r-project.org")
  ragg::agg_png(out_png, width=1400, height=900, res=120, units="px"); draw_plot(); dev.off()
}

cat("[OK] Wrote:", out_pdf, "and", out_png, "\n")
RSCRIPT
