#!/usr/bin/env bash
#SBATCH --job-name=bed_genespace
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:15:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/bed_genespace_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/bed_genespace_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
FINAL="$WORKDIR/maker/final"
GSDIR="$WORKDIR/genespace_input"

mkdir -p "$GSDIR/bed" "$GSDIR/peptide"

# 1) BED (0-based start) from renamed GFF
GFF="$FINAL/assembly.all.maker.noseq.renamed.gff"
BED="$GSDIR/bed/Athaliana.bed"

grep -P $'\tgene\t' "$GFF" | \
awk 'BEGIN{OFS="\t"}{
  # col9 like: ID=ATML..., take the first tag as ID
  split($9,a,";"); split(a[1],b,"=");
  print $1, $4-1, $5, b[2]
}' > "$BED"

# 2) Peptide FASTA (your proteome)
cp "$FINAL/proteins.renamed.fasta.Uniprot" "$GSDIR/peptide/Athaliana.fa"

echo "[DONE] BED: $BED"
echo "[DONE] FASTA: $GSDIR/peptide/Athaliana.fa"
