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

export WORKDIR
export TOP_N=6         # max number of tracks (ignored if only All_TEs)
export N_SCAFFOLDS=10  # longest scaffolds
export WINDOW=100000   # window (bp)

export R_LIBS_USER="${WORKDIR}/.Rlib"
module load R 2>/dev/null || true

Rscript - <<'RSCRIPT'
suppressPackageStartupMessages({
  library(data.table)
  library(circlize)
})

workdir <- Sys.getenv("WORKDIR")
edta    <- file.path(workdir, "results/EDTA_annotation")
figdir  <- file.path(workdir, "results/figures")

gff   <- file.path(edta, "hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3")
topN  <- as.integer(Sys.getenv("TOP_N", "6"))
nScaf <- as.integer(Sys.getenv("N_SCAFFOLDS", "10"))
win   <- as.integer(Sys.getenv("WINDOW", "100000"))

stopifnot(file.exists(gff))
message("[INFO] Reading TE GFF: ", gff)

## -------- read GFF (strip comments) --------
all_lines  <- readLines(gff, warn = FALSE)
data_lines <- all_lines[!startsWith(all_lines, "#") & nzchar(all_lines)]
tmp <- tempfile(fileext = ".gff3")
writeLines(data_lines, tmp)

dt <- fread(
  tmp,
  sep = "\t",
  header = FALSE,
  fill = TRUE,
  data.table = TRUE,
  quote = ""
)
unlink(tmp)

if (ncol(dt) < 9) stop("GFF has < 9 columns after parsing.")
dt <- dt[, 1:9]
setnames(dt, c("chr","src","type","start","end","score","strand","phase","attr"))

dt[, start := as.numeric(start)]
dt[, end   := as.numeric(end)]
dt <- dt[!is.na(start) & !is.na(end) & end >= start]

## -------- try to get a TE class / superfamily --------
extract_attr <- function(x, key) {
  # x: character vector of attribute fields
  # returns: character vector of values or NA
  sapply(strsplit(x, ";"), function(parts) {
    hit <- grep(paste0("^", key, "="), parts, value = TRUE)
    if (length(hit) == 0) return(NA_character_)
    sub(paste0("^", key, "="), "", hit[1])
  })
}

keys_to_try <- c("Superfamily","Classification","Class","class","Family","family")

Superfamily <- NULL
for (k in keys_to_try) {
  vals <- extract_attr(dt$attr, k)
  if (!all(is.na(vals))) {
    Superfamily <- vals
    message("[INFO] Using TE class key: ", k)
    break
  }
}

if (is.null(Superfamily)) {
  message("[WARN] Could not find any TE class key; using single track 'All_TEs'.")
  dt[, Superfamily := "All_TEs"]
} else {
  dt[, Superfamily := Superfamily]
  dt[is.na(Superfamily) | Superfamily == "", Superfamily := "Other"]
}

dt[, len := pmax(1, end - start + 1)]

## -------- choose superfamilies (or All_TEs) --------
if (length(unique(dt$Superfamily)) == 1L) {
  top_sf <- "All_TEs"
} else {
  top_sf <- dt[, .(bp = sum(len, na.rm = TRUE)), by = Superfamily][
    order(-bp)
  ][1:min(topN, .N), Superfamily]
}

message("[INFO] Superfamilies to plot: ", paste(unique(top_sf), collapse = ", "))

tracks <- dt[Superfamily %in% top_sf, .(chr, start, end, Superfamily)]

if (nrow(tracks) == 0L) stop("No TE intervals to plot (after filtering).")

## -------- build ideogram from TE coords --------
ideoDT <- tracks[, .(start = 0, end = max(end, na.rm = TRUE)), by = chr]
ideoDT <- ideoDT[order(-end)][1:min(nScaf, .N)]
tracks <- tracks[chr %in% ideoDT$chr]

if (nrow(tracks) == 0L) stop("No TE records remain after restricting to top scaffolds.")

message("[INFO] Plotting ", length(unique(ideoDT$chr)), " scaffolds")

## -------- draw circular TE density plot --------
draw_plot <- function() {
  circos.clear()
  circos.par(start.degree = 90,
             gap.degree   = 1,
             track.margin = c(0.01, 0.01))

  circos.genomicInitialize(ideoDT)

  cols <- setNames(rainbow(length(top_sf)), top_sf)

  for (sf in top_sf) {
    seg_dt <- tracks[Superfamily == sf, .(chr, start, end)]
    if (nrow(seg_dt) == 0L) next
    seg <- as.data.frame(seg_dt)
    seg$start <- as.numeric(seg$start)
    seg$end   <- as.numeric(seg$end)
    seg <- seg[seg$end >= seg$start, ]
    if (nrow(seg) == 0L) next

    circos.genomicDensity(
      seg,
      col          = cols[sf],
      track.height = 0.08,
      window.size  = win,
      border       = NA
    )
  }

  circos.clear()
}

out_pdf <- file.path(figdir, "02_TE_density_circlize.pdf")
out_png <- file.path(figdir, "02_TE_density_circlize.png")

pdf(out_pdf, width = 10, height = 8); draw_plot(); dev.off()
png(out_png, width = 1400, height = 1100, res = 150); draw_plot(); dev.off()

message("[OK] Wrote TE density plot to:")
message("  ", out_pdf)
message("  ", out_png)
RSCRIPT
