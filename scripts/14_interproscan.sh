#!/bin/bash
#SBATCH --job-name=iprscan
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

COURSEDIR="/data/courses/assembly-annotation-course/CDS_annotation"
INP="maker/final/proteins.renamed.fasta"
OUT="maker/final/output.iprscan"

mkdir -p maker/final

apptainer exec \
  --bind $COURSEDIR/data/interproscan-5.70-102.0/data:/opt/interproscan/data \
  --bind $PWD \
  $COURSEDIR/containers/interproscan_latest.sif \
  /opt/interproscan/interproscan.sh \
  -appl pfam --disable-precalc -f TSV \
  --goterms --iprlookup --seqtype p \
  -i "$INP" -o "$OUT"
