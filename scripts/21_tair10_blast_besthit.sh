#!/usr/bin/env bash
#SBATCH --job-name=tair10_blast
#SBATCH --cpus-per-task=10
#SBATCH --mem=32G
#SBATCH --time=08:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/tair10_blast_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/tair10_blast_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
FINAL="$WORKDIR/maker/final"

# autodetect proteins FASTA
if [[ -s "$FINAL/proteins.renamed.fasta" ]]; then
  PROT="$FINAL/proteins.renamed.fasta"
elif [[ -s "$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta" ]]; then
  PROT="$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta"
else
  echo "[ERR] Cannot find a renamed proteins FASTA in $FINAL"; exit 1
fi

TAIR_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_pep_20110103_representative_gene_model"
OUTDIR="$WORKDIR/results/tair10"
BLAST_OUT="$OUTDIR/maker_vs_tair10.tsv"
BESTHITS="${BLAST_OUT}.besthits"

mkdir -p "$OUTDIR"
module load BLAST+/2.15.0-gompi-2021a || true

echo "[INFO] BLASTP vs TAIR10 representative"
blastp -query "$PROT" -db "$TAIR_DB" \
  -num_threads "${SLURM_CPUS_PER_TASK:-10}" \
  -outfmt 6 -evalue 1e-5 -max_target_seqs 10 -out "$BLAST_OUT"

echo "[INFO] Best hit per query"
sort -k1,1 -k12,12g "$BLAST_OUT" | sort -u -k1,1 --merge > "$BESTHITS"

echo "[DONE] $BESTHITS"
