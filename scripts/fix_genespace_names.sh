#!/usr/bin/env bash
#SBATCH --job-name=fix_gs_restore
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/fix_genespace_restore_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/fix_genespace_restore_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation/genespace_input"
BEDRAW="$WORKDIR/bed_raw"
PEPRAW="$WORKDIR/peptide_raw"
BED="$WORKDIR/bed"
PEP="$WORKDIR/peptide"

mkdir -p "$BED" "$PEP"

# function to make IDs GENESPACE-safe
sanitize() {
  printf "%s\n" "$1" | sed -E 's/[^A-Za-z0-9_.]/_/g'
}

echo "=== Restoring BED files ==="
shopt -s nullglob
for src in "$BEDRAW"/*.bed; do
  base="$(basename "$src")"         # e.g. Altai-5.EVM...bed or Athaliana.bed
  stem="${base%.bed}"
  clean_stem="$(sanitize "$stem")"  # Altai_5..., Athaliana
  dest="$BED/${clean_stem}.bed"
  cp "$src" "$dest"
  echo "  $src -> $dest"
done

echo "=== Restoring peptide files ==="
for src in "$PEPRAW"/*; do
  base="$(basename "$src")"
  # handle things like Altai-5.protein.faa, TAIR10.fa, Athaliana.fa
  stem="${base%.protein.faa}"
  [[ "$stem" == "$base" ]] && stem="${base%.faa}"
  stem="${stem%.fa}"
  clean_stem="$(sanitize "$stem")"
  dest="$PEP/${clean_stem}.fa"
  cp "$src" "$dest"
  echo "  $src -> $dest"
done
shopt -u nullglob

echo "=== Final BED files ==="
ls -1 "$BED" || true
echo "=== Final peptide files ==="
ls -1 "$PEP" || true

echo "[DONE] Restored and sanitized BED/peptide files."
