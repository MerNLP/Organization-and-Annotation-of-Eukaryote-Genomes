#!/usr/bin/env bash
#SBATCH --job-name=TEsorter
#SBATCH --cpus-per-task=12
#SBATCH --mem=24G
#SBATCH --time=12:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/tesorter_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/tesorter_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
TES_OUT="${WORKDIR}/results/TEsorter"
mkdir -p "${TES_OUT}"

# Inputs per handout
LTR_RAW_FA="${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.raw/hifiasm.p_ctg.fa.mod.LTR.raw.fa"

# Course container
TESORTER_SIF="/data/courses/assembly-annotation-course/CDS_annotation/containers/TEsorter_1.3.0.sif"

# Run TEsorter (rexdb-plant)
apptainer exec --bind "${WORKDIR}" "${TESORTER_SIF}" \
  TEsorter "${LTR_RAW_FA}" -db rexdb-plant -p "${SLURM_CPUS_PER_TASK}"


mv "${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.raw/hifiasm.p_ctg.fa.mod.LTR.raw.fa".rexdb-plant.* "${TES_OUT}/" 2>/dev/null || true

echo "[OK] TEsorter done. Outputs in: ${TES_OUT}"
