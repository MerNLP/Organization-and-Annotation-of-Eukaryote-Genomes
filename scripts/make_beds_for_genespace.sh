#!/usr/bin/env bash
#SBATCH --job-name=make_beds_genespace
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/make_beds_genespace_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/make_beds_genespace_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
GSDIR="$WORKDIR/genespace_input"
BEDDIR="$GSDIR/bed"
PEPDIR="$GSDIR/peptide"
GFFDIR="/data/courses/assembly-annotation-course/CDS_annotation/data/Lian_et_al/gene_gff/selected"
TAIR_BED="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10.bed"
RENAMED_GFF="$WORKDIR/maker/final/assembly.all.maker.noseq.renamed.gff"   # your GFF
ATH_BED="$BEDDIR/Athaliana.bed"

mkdir -p "$BEDDIR" "$PEPDIR"

echo "=== Making BEDs for GENESPACE ==="

# 0) TAIR10 (copy if not already present)
if [[ -s "$TAIR_BED" ]]; then
  cp -n "$TAIR_BED" "$BEDDIR/" && echo "[OK] TAIR10.bed copied" || echo "[SKIP] TAIR10.bed already present"
else
  echo "[WARN] TAIR10.bed not found at $TAIR_BED (not fatal if you’ll add later)."
fi


if [[ -s "$ATH_BED" ]]; then
  echo "[SKIP] $ATH_BED already exists"
else
  echo "[BUILD] $ATH_BED from $RENAMED_GFF"
  grep -P $'\tgene\t' "$RENAMED_GFF" | \
  awk 'BEGIN{OFS="\t"}{
    split($9,a,";"); split(a[1],b,"=");
    print $1, $4-1, $5, b[2]
  }' > "$ATH_BED"
  echo "[DONE] $ATH_BED"
fi


shopt -s nullglob
for gff in "$GFFDIR"/*.gff; do
  base=$(basename "$gff" .EVM.v3.5.ann.protein_coding_genes.gff)
  out="$BEDDIR/${base}.bed"
  if [[ -s "$out" ]]; then
    echo "[SKIP] $out already exists"
    continue
  fi
  echo "[BUILD] $out from $gff"
  awk 'BEGIN{OFS="\t"} $3=="gene"{
    split($9,a,";"); split(a[1],b,"=");
    print $1, $4-1, $5, b[2]
  }' "$gff" > "$out"
  echo "[DONE] $out"
done
shopt -u nullglob

echo "=== BEDs present in $BEDDIR ==="
ls -lh "$BEDDIR" || true

echo "BED generation finished."
