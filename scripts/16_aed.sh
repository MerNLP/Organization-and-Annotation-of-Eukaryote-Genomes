#!/bin/bash
#SBATCH --job-name=aed
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

MAKERBIN="/data/courses/assembly-annotation-course/CDS_annotation/softwares/Maker_v3.01.03/src/bin"
REN_GFF="maker/final/assembly.all.maker.noseq.renamed.gff"
OUT="maker/final/AED.txt"

# Sanity
[ -s "$REN_GFF" ] || { echo "Missing or empty: $REN_GFF"; exit 2; }

perl "$MAKERBIN/AED_cdf_generator.pl" -b 0.025 "$REN_GFF" > "$OUT"

echo "AED head:"
head -n 8 "$OUT" || true

# Optional: percent with AED <= 0.5
awk '$1!~/^#/ && $1<=0.5{p=$2} END{if(p=="")p=0; printf("pct_AED<=0.5: %.1f%%\n", p*100)}' "$OUT"
