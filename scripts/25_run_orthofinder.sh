#!/usr/bin/env bash
#SBATCH --job-name=orthofinder
#SBATCH --cpus-per-task=20
#SBATCH --mem=64G
#SBATCH --time=2-00:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/orthofinder_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/orthofinder_%j.e

set -euo pipefail
echo "=== STEP 25: Running OrthoFinder ==="

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
ORTHO_DIR="$WORKDIR/orthofinder_input"
OUTDIR="$WORKDIR/orthofinder_results"

mkdir -p "$OUTDIR"

# --- Load OrthoFinder module ---
module load OrthoFinder/2.5.5-foss-2021a

# --- Run OrthoFinder ---
orthofinder -f "$ORTHO_DIR" -t 20 -a 20 -M msa -A mafft -T fasttree -S diamond -o "$OUTDIR"

echo "[DONE] OrthoFinder completed."
echo "Results are in: $OUTDIR"
