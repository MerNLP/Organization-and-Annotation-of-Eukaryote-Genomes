#!/bin/bash
#SBATCH --job-name=ipr_update
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:15:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

MAKERBIN="/data/courses/assembly-annotation-course/CDS_annotation/softwares/Maker_v3.01.03/src/bin"
IN_GFF="maker/final/assembly.all.maker.noseq.renamed.gff"
IN_IPR="maker/final/output.iprscan"
OUT_GFF="maker/final/assembly.all.maker.renamed.iprscan.gff"

"$MAKERBIN/ipr_update_gff" "$IN_GFF" "$IN_IPR" > "$OUT_GFF"

echo "Updated GFF:" && ls -lh "$OUT_GFF"
# show a few tags to confirm
grep -m10 -E "IPR[0-9]{6}|PF[0-9]{5}|GO:" "$OUT_GFF" || true
