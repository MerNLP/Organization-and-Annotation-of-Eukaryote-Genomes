#!/usr/bin/env bash
#SBATCH --job-name=EDTA_summary
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/edta_summary_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/edta_summary_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
SUMFILE="${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.TEanno.sum"
OUT_TSV="${EDTA_OUT}/superfamily_summary.tsv"

if [[ ! -s "${SUMFILE}" ]]; then
  echo "[ERR] Missing EDTA summary: ${SUMFILE}" >&2
  exit 1
fi

awk '
  BEGIN{
    OFS="\t";
    print "Superfamily","Count","bpMasked","Percent_masked"
  }
  {
    line=$0
    gsub("\r","",line)
    gsub(",","",line)
    sub(/^[[:space:]]+/,"",line)     # trim leading spaces
  }
  # only rows that end with % value
  /[0-9.]+%[[:space:]]*$/ {
    # skip headers / section titles / separators
    if (line ~ /^(Repeat[[:space:]]+Classes|Total[[:space:]]+Sequences:|Total[[:space:]]+Length:|Class[[:space:]]|Seq[[:space:]]|=====|LINE[[:space:]]+--|LTR[[:space:]]+--|TIR[[:space:]]+--|nonTIR[[:space:]]+--)[[:space:]]*$/) next

    # parse from the right edge: <name> <count> <bp> <pct%>
    if (match(line, /(.*)[[:space:]]+([0-9-]+)[[:space:]]+([0-9]+)[[:space:]]+([0-9.]+)%[[:space:]]*$/, m)) {
      name=m[1]; cnt=m[2]; bp=m[3]; pct=m[4]

      # skip category rows (count shown as --)
      if (cnt == "--") next

      # normalize name
      gsub(/^[[:space:]]+|[[:space:]]+$/,"",name)
      if (name ~ /^total[[:space:]_]*interspersed$/) name="total_interspersed"

      # drop non-superfamily / per-locus / per-family lines
      if (name == "Total") next
      if (name ~ /^TE_/) next                # per-family IDs
      if (name ~ /:/) next                   # contig:START..END
      if (name ~ /\.\./) next                # coordinates pattern
      if (name == "45S" || name == "repeat_fragment") next

      # keep
      print name, cnt, bp, pct
    }
  }
' "${SUMFILE}" \
| awk 'NR==1{print; next} {print | "sort -k3,3nr"}' \
> "${OUT_TSV}"

echo "[OK] Wrote: ${OUT_TSV}"
head -n 30 "${OUT_TSV}"
