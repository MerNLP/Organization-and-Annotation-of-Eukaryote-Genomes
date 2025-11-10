#!/bin/bash
#SBATCH --job-name=agat_stats_slim
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=32G
#SBATCH --time=00:30:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

IN_GFF="maker/final/assembly.all.maker.renamed.iprscan.gff"
OUT_TXT="maker/final/annotation.stats.txt"
SLIM_GFF="maker/final/assembly.slim.gff"

[ -s "$IN_GFF" ] || { echo "ERROR: Missing/empty $IN_GFF"; exit 2; }

# Make slim GFF (keep header + gene/mRNA/exon/CDS)
awk 'BEGIN{FS=OFS="\t"}
  /^#/ {print; next}
  $3=="gene" || $3=="mRNA" || $3=="exon" || $3=="CDS" {print}
' "$IN_GFF" > "$SLIM_GFF"

echo "Slim GFF size:"
ls -lh "$SLIM_GFF"

# Find or pull SIF
SIF=""
for d in container containers; do
  if [ -s "$d/agat_1.2.0.sif" ]; then SIF="$d/agat_1.2.0.sif"; break; fi
done
if [ -z "$SIF" ]; then
  echo "Pulling AGAT SIF..."
  mkdir -p containers
  export TMPDIR="${SLURM_TMPDIR:-$PWD/containers/tmp}"
  mkdir -p "$TMPDIR"
  apptainer pull containers/agat_1.2.0.sif docker://quay.io/biocontainers/agat:1.2.0--pl5321hdfd78af_0
  SIF="containers/agat_1.2.0.sif"
fi

# Remove stale output; run AGAT on the slimmed file
[ ! -e "$OUT_TXT" ] || rm -f "$OUT_TXT"

apptainer exec --bind "$PWD":"$PWD" --pwd "$PWD" "$SIF" \
  agat_sp_statistics.pl -i "$SLIM_GFF" -o "$OUT_TXT" -v 1

[ -s "$OUT_TXT" ] || { echo "ERROR: $OUT_TXT is empty"; exit 4; }
echo "Wrote: $OUT_TXT"
head -n 25 "$OUT_TXT" || true
