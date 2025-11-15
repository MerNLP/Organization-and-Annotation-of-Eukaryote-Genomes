#!/usr/bin/env bash
#SBATCH --job-name=fix_gs_gene_ids
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/fix_genespace_gene_ids_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/fix_genespace_gene_ids_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation/genespace_input"
BEDDIR="$WORKDIR/bed"
PEPDIR="$WORKDIR/peptide"

echo "=== Fixing ':' in BED gene IDs ==="
shopt -s nullglob
for bed in "$BEDDIR"/*.bed; do
  tmp="${bed}.tmp"
  awk 'BEGIN{OFS="\t"}{
    gsub(":", "_", $4);
    print
  }' "$bed" > "$tmp"
  mv "$tmp" "$bed"
  echo "  cleaned: $(basename "$bed")"
done

echo "=== Fixing ':' in peptide FASTA headers ==="
for fa in "$PEPDIR"/*.fa; do
  tmp="${fa}.tmp"
  awk '{
    if ($0 ~ /^>/) {
      sub(/^>/, "", $0);
      gsub(":", "_", $0);
      print ">" $0;
    } else {
      print;
    }
  }' "$fa" > "$tmp"
  mv "$tmp" "$fa"
  echo "  cleaned: $(basename "$fa")"
done
shopt -u nullglob

echo "[DONE] Replaced ':' with '_' in gene IDs in BED + FASTA."
