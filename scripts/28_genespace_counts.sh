#!/usr/bin/env bash
#SBATCH --job-name=genespace_counts
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/genespace_counts_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/genespace_counts_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
GSDIR="$WORKDIR/genespace_input"
SIF="/data/courses/assembly-annotation-course/CDS_annotation/containers/genespace_latest.sif"

echo "=== GENESPACE: count core & accession-specific genes ==="
echo "[INFO] Working dir: $WORKDIR"
echo "[INFO] Genespace dir: $GSDIR"

apptainer exec \
  --bind "$WORKDIR":"$WORKDIR" \
  --bind /data/courses/assembly-annotation-course:/data/courses/assembly-annotation-course \
  "$SIF" \
  Rscript "$WORKDIR/scripts/genespace_counts_from_rds.R" "$GSDIR" Athaliana

echo "[DONE] genespace_counts."
