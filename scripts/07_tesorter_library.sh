#!/usr/bin/env bash
#SBATCH --job-name=TEsorter_lib
#SBATCH --cpus-per-task=12
#SBATCH --mem=16G
#SBATCH --time=04:00:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/tesorter_lib_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/tesorter_lib_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
LIB="${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.TElib.fa"
OUT="${WORKDIR}/results/TEsorter_all"
SIF="/data/courses/assembly-annotation-course/CDS_annotation/containers/TEsorter_1.3.0.sif"
mkdir -p "${OUT}"

if [[ ! -s "${LIB}" ]]; then
  echo "[ERR] Missing EDTA library: ${LIB}" >&2
  exit 1
fi

echo "[INFO] Extracting Copia & Gypsy from ${LIB}"


if command -v seqkit >/dev/null 2>&1; then
  seqkit grep -r -p "Copia" "${LIB}" > "${OUT}/Copia_sequences.fa"
  seqkit grep -r -p "Gypsy" "${LIB}" > "${OUT}/Gypsy_sequences.fa"
else
  # AWK FASTA filter by header substring (case-insensitive)
  awk_ci_fa () {
    local pat="$1" in="$2" out="$3"
    awk -v pat="$pat" '
      BEGIN{IGNORECASE=1; RS=">"; ORS=""}
      NR>1{
        nl=index($0,"\n");
        h=substr($0,1,nl-1);
        s=substr($0,nl+1);
        if (h ~ pat) { printf(">%s\n%s", h, s) }
      }' "$in" > "$out"
  }
  awk_ci_fa "Copia" "${LIB}" "${OUT}/Copia_sequences.fa"
  awk_ci_fa "Gypsy" "${LIB}" "${OUT}/Gypsy_sequences.fa"
fi


for f in Copia_sequences.fa Gypsy_sequences.fa; do
  if [[ ! -s "${OUT}/${f}" ]]; then
    echo "[ERR] No sequences extracted into ${OUT}/${f}. Check headers in ${LIB}." >&2
    exit 2
  fi
done

echo "[INFO] Running TEsorter (rexdb-plant) on Copia & Gypsy"
apptainer exec --bind "${WORKDIR}" "${SIF}" \
  TEsorter "${OUT}/Copia_sequences.fa" -db rexdb-plant -p "${SLURM_CPUS_PER_TASK}"

apptainer exec --bind "${WORKDIR}" "${SIF}" \
  TEsorter "${OUT}/Gypsy_sequences.fa"  -db rexdb-plant -p "${SLURM_CPUS_PER_TASK}"

COP="${OUT}/Copia_sequences.fa.rexdb-plant.cls.tsv"
GYP="${OUT}/Gypsy_sequences.fa.rexdb-plant.cls.tsv"

if [[ ! -s "${COP}" || ! -s "${GYP}" ]]; then
  echo "[ERR] Missing TEsorter classification tsv. Expected:"
  echo "  ${COP}"
  echo "  ${GYP}"
  exit 3
fi

echo "[INFO] Summarizing clade counts"
awk -F'\t' 'BEGIN{OFS="\t";print "Clade","Count"} NR>1 && $4!="" {print $4}' "${COP}" \
  | sort | uniq -c | awk '{print $2"\t"$1}' > "${OUT}/Copia_clade_counts.tsv"

awk -F'\t' 'BEGIN{OFS="\t";print "Clade","Count"} NR>1 && $4!="" {print $4}' "${GYP}" \
  | sort | uniq -c | awk '{print $2"\t"$1}' > "${OUT}/Gypsy_clade_counts.tsv"

echo "[OK] Wrote:"
echo "  ${OUT}/Copia_clade_counts.tsv"
echo "  ${OUT}/Gypsy_clade_counts.tsv"
