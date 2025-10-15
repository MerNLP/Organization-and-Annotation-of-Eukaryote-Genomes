#!/usr/bin/env bash
#SBATCH --job-name=EDTA
#SBATCH --cpus-per-task=20
#SBATCH --mem=128G
#SBATCH --time=2-00:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/edta_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/edta_%j.e

set -euo pipefail

# Paths
WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
GENOME="/data/users/mlawrence/assembly_annotation_course/assemblies/hifiasm/hifiasm.p_ctg.fa"  # existing FASTA
OUT="${WORKDIR}/results/EDTA_annotation"

# Course container + TAIR10 CDS
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/EDTA2.2.sif"
CDS="/data/courses/assembly-annotation-course/CDS_annotation/data/TAIR10_cds_20110103_representative_gene_model_updated"

mkdir -p "${WORKDIR}/logs" "${OUT}"
cd "${OUT}"

apptainer exec \
  --bind "${WORKDIR},/data/courses/assembly-annotation-course" \
  "${CONTAINER}" \
  EDTA.pl \
    --genome "${GENOME}" \
    --species others \
    --step all \
    --sensitive 1 \
    --cds "${CDS}" \
    --anno 1 \
    --threads "${SLURM_CPUS_PER_TASK}" \
    --overwrite 1

# Normalize common outputs for downstream steps
lib=$(ls *.TElib.fa    2>/dev/null | head -n1 || true)
gff=$(ls *.TEanno.gff3 2>/dev/null | head -n1 || true)
[[ -n "${lib}" ]] && cp "${lib}" ath.EDTA.TElib.fa
[[ -n "${gff}" ]] && cp "${gff}" ath.EDTA.TEanno.gff3

echo "EDTA done."
echo "Library: ${OUT}/ath.EDTA.TElib.fa"
echo "GFF3:    ${OUT}/ath.EDTA.TEanno.gff3"
