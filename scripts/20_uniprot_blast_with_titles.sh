#!/usr/bin/env bash
#SBATCH --job-name=uniprot_blast_titles
#SBATCH --cpus-per-task=10
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/uniprot_blast_titles_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/uniprot_blast_titles_%j.e

set -euo pipefail
WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
FINAL="$WORKDIR/maker/final"
OUTDIR="$WORKDIR/results/uniprot"
mkdir -p "$OUTDIR"

# autodetect proteins FASTA
if [[ -s "$FINAL/proteins.renamed.fasta" ]]; then
  PROT="$FINAL/proteins.renamed.fasta"
elif [[ -s "$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta" ]]; then
  PROT="$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta"
else
  echo "[ERR] Cannot find renamed proteins FASTA in $FINAL"; exit 1
fi

UNIPROT_DB="/data/courses/assembly-annotation-course/CDS_annotation/data/uniprot/uniprot_viridiplantae_reviewed.fa"
RAW="$OUTDIR/maker_vs_uniprot.stitle.tsv"
BEST="$OUTDIR/maker_vs_uniprot.stitle.best.tsv"

module load BLAST+/2.15.0-gompi-2021a || true

echo "[INFO] BLASTP with titles (stitle) in output"
# outfmt columns: qseqid sacc stitle evalue bitscore
blastp \
  -query "$PROT" \
  -db "$UNIPROT_DB" \
  -num_threads "${SLURM_CPUS_PER_TASK:-10}" \
  -outfmt '6 qseqid sacc stitle evalue bitscore' \
  -evalue 1e-5 \
  -max_target_seqs 10 \
  -out "$RAW"

echo "[INFO] Keep best hit per query by lowest evalue, tie-break by higher bitscore"
# sort by qid, evalue asc (col4 numeric), bitscore desc (col5 numeric, use reverse)
# then unique by qid
sort -t$'\t' -k1,1 -k4,4g -k5,5gr "$RAW" | awk -F'\t' '!seen[$1]++' > "$BEST"

echo "[DONE] Besthit table with titles: $BEST"
