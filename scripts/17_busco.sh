#!/bin/bash
#SBATCH --job-name=busco_maker_prot
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

module load BUSCO/5.4.2-foss-2021a

INP="maker/final/proteins.renamed.fasta"
LINEAGE="brassicales_odb10"
OUTDIR="busco_maker_proteins"

# Sanity
[ -s "$INP" ] || { echo "Missing or empty: $INP"; exit 2; }

busco -i "$INP" -l "$LINEAGE" -o "$OUTDIR" -m proteins

echo "BUSCO summary:"
grep -E "C:|D:|F:|M:" ${OUTDIR}/short_summary*.txt || true
