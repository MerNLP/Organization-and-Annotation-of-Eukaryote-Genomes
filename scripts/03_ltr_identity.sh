#!/usr/bin/env bash
#SBATCH --job-name=LTR_identity
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/ltr_identity_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/ltr_identity_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
RUNDIR="${WORKDIR}/results/ltr_identity_run"
GFF_SRC="${WORKDIR}/results/EDTA_annotation/hifiasm.p_ctg.fa.mod.EDTA.raw/hifiasm.p_ctg.fa.mod.LTR.intact.raw.gff3"
CLS_SRC="${WORKDIR}/results/TEsorter/hifiasm.p_ctg.fa.mod.LTR.raw.fa.rexdb-plant.cls.tsv"
RSCRIPT="/data/courses/assembly-annotation-course/CDS_annotation/scripts/02-full_length_LTRs_identity.R"

mkdir -p "${RUNDIR}/plots"
cd "${RUNDIR}"

ln -sf "${GFF_SRC}" genomic.fna.mod.LTR.intact.raw.gff3
ln -sf "${CLS_SRC}" genomic.fna.mod.LTR.raw.fa.rexdb-plant.cls.tsv

export R_LIBS_USER="/data/users/mlawrence/eukaryote_genome_annotation/.Rlib"

module load R 2>/dev/null || true
Rscript "${RSCRIPT}"

