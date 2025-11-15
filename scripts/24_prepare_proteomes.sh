#!/usr/bin/env bash
#SBATCH --job-name=prepare_proteomes
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=00:30:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/prepare_proteomes_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/prepare_proteomes_%j.e

set -euo pipefail
echo "=== STEP 24: Preparing OrthoFinder input proteomes ==="

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
ORTHO_DIR="$WORKDIR/orthofinder_input"
SRC="/data/courses/assembly-annotation-course/CDS_annotation/data/Lian_et_al/protein/selected"
TAIR10="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10.fa"

mkdir -p "$ORTHO_DIR"

# 1) Your own proteome
cp "$WORKDIR/maker/final/proteins.renamed.fasta.Uniprot" "$ORTHO_DIR/Athaliana.faa"

# 2) Course accessions (ignore .bak files)
for f in "$SRC"/*.protein.faa; do
    base=$(basename "$f")
    cp "$f" "$ORTHO_DIR/$base"
done

# 3) TAIR10 reference (if available)
if [[ -s "$TAIR10" ]]; then
    cp "$TAIR10" "$ORTHO_DIR/"
fi

# 4) Summary
echo "[INFO] Copied proteomes to $ORTHO_DIR:"
ls -lh "$ORTHO_DIR"
