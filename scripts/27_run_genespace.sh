#!/usr/bin/env bash
#SBATCH --job-name=genespace
#SBATCH --cpus-per-task=20
#SBATCH --mem=64G
#SBATCH --time=1-00:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/genespace_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/genespace_%j.e

# =========================================================
# Step 27: Run GENESPACE
# Goal: Perform orthology- and synteny-aware comparative
#       genomics using GENESPACE (OrthoFinder + MCScanX)
# Input:
#   - BED files (genespace_input/bed/*.bed)
#   - Peptide FASTAs (genespace_input/peptide/*.fa)
# Container:
#   /data/courses/assembly-annotation-course/CDS_annotation/containers/genespace_latest.sif
# Output:
#   - pangenome_matrix.rds
#   - genespace_results/*.tsv (core, accessory, unique gene stats)
# =========================================================

set -euo pipefail
echo "=== GENESPACE: normalize inputs + run ==="

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
GSDIR="$WORKDIR/genespace_input"
BEDDIR="$GSDIR/bed"
PEPDIR="$GSDIR/peptide"
SIF="/data/courses/assembly-annotation-course/CDS_annotation/containers/genespace_latest.sif"

# 0) Safety checks
[[ -d "$BEDDIR" && -d "$PEPDIR" ]] || { echo "[ERR] Missing $BEDDIR or $PEPDIR"; exit 2; }
[[ -s "$BEDDIR/Athaliana.bed" ]] || { echo "[ERR] Missing Athaliana.bed"; exit 2; }
[[ -s "$PEPDIR/Athaliana.fa"  ]] || { echo "[ERR] Missing Athaliana.fa"; exit 2; }
[[ -s "$SIF" ]] || { echo "[ERR] Container not found: $SIF"; exit 2; }

# 1) Normalize peptide filenames to match BED basenames
shopt -s nullglob
for faa in "$PEPDIR"/*.protein.faa; do
  base=$(basename "$faa" .protein.faa)
  link="$PEPDIR/${base}.fa"
  if [[ ! -e "$link" ]]; then
    ln -s "$(basename "$faa")" "$link"
    echo "[LINK] $link -> $(basename "$faa")"
  fi
done
shopt -u nullglob

# 2) Quick listing for sanity
echo "[INFO] BED files:"
ls -1 "$BEDDIR"
echo "[INFO] Peptide files (normalized):"
ls -1 "$PEPDIR" | sed 's/^/  /'

# 3) Make results dir
mkdir -p "$GSDIR/genespace_results"

# 4) Run GENESPACE container with R script
apptainer exec \
  --bind "$WORKDIR":"$WORKDIR" \
  --bind /data/courses/assembly-annotation-course:/data/courses/assembly-annotation-course \
  "$SIF" \
  Rscript "$WORKDIR/scripts/genespace.R" "$GSDIR"

echo "[DONE] GENESPACE complete."
echo "Check: $GSDIR/pangenome_matrix.rds"
echo "       $GSDIR/genespace_results/per_accession_core_accessory_unique_genes.tsv"
echo "       $GSDIR/genespace_results/Athaliana_core_accessory_unique_genes.tsv"
echo "       $GSDIR/genespace_results/orthogroup_category_counts.tsv"
