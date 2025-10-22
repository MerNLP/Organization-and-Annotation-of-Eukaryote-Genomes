#!/usr/bin/env bash
#SBATCH --job-name=ideogram
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/ideogram_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/ideogram_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
GENOME="/data/users/mlawrence/assembly_annotation_course/assemblies/hifiasm/hifiasm.p_ctg.fa"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
IDEO="${EDTA_OUT}/ideogram.tsv"

mkdir -p "${EDTA_OUT}"

# Try to use seqkit if available; else use existing .fai; else fallback to awk (slowest).
if command -v seqkit >/dev/null 2>&1; then
  echo "[INFO] Using seqkit to compute scaffold lengths"
  seqkit fx2tab -nl "${GENOME}" | awk 'BEGIN{OFS="\t"} {print $1,0,$2}' > "${IDEO}"
elif [[ -s "${GENOME}.fai" ]]; then
  echo "[INFO] Using existing FASTA index: ${GENOME}.fai"
  awk 'BEGIN{OFS="\t"} {print $1,0,$2}' "${GENOME}.fai" > "${IDEO}"
else
  echo "[WARN] seqkit and samtools not available; falling back to awk length counter"
  awk 'BEGIN{OFS="\t";h="";len=0}
       /^>/{
         if(h!=""){print h,0,len}
         h=substr($0,2); len=0; next
       }
       {gsub(/[ \t\r]/,""); len+=length($0)}
       END{if(h!=""){print h,0,len}}' "${GENOME}" > "${IDEO}"
fi

echo "[OK] Wrote ideogram: ${IDEO}"
head -n 5 "${IDEO}" || true
