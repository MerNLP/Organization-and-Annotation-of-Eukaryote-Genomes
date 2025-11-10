#!/bin/bash
#SBATCH --job-name=auto_fix_rename
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:10:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

PREFIX="ATML"
MAKERBIN="/data/courses/assembly-annotation-course/CDS_annotation/softwares/Maker_v3.01.03/src/bin"

SRC_GFF="maker/assembly.all.maker.noseq.gff"
PROT_IN="maker/hifiasm.p_ctg.all.maker.proteins.fasta"
TX_IN="maker/hifiasm.p_ctg.all.maker.transcripts.fasta"

OUTDIR="maker/final"
REN_GFF="$OUTDIR/assembly.all.maker.noseq.renamed.gff"
REN_PROT="$OUTDIR/proteins.renamed.fasta"
REN_TX="$OUTDIR/transcripts.renamed.fasta"
MAP="$OUTDIR/id.map"

mkdir -p "$OUTDIR"

echo "== Sanity checks =="
for f in "$SRC_GFF" "$PROT_IN" "$TX_IN"; do
  [ -s "$f" ] || { echo "ERROR: Missing or empty input: $f" >&2; exit 2; }
done

echo "== Detect if SRC_GFF already has ATML IDs on mRNAs =="
if grep -q -m1 -o 'ID=ATML[0-9]\{7\}-R[A-Z]' "$SRC_GFF"; then
  echo "Detected ATML IDs in source GFF. Skipping GFF renaming."
  # Use the source as the 'renamed' GFF (copy to consistent path)
  cp -f "$SRC_GFF" "$REN_GFF"
else
  echo "No ATML IDs found in source GFF. Building id.map and renaming…"
  "$MAKERBIN/maker_map_ids" --prefix "$PREFIX" --justify 7 "$SRC_GFF" > "$MAP"
  head -n 6 "$MAP" || true

  # If maker_map_ids (for any reason) produced ATML->ATML pairs,
  # still attempt map_gff_ids; if it yields empty, fallback to copy SRC_GFF.
  "$MAKERBIN/map_gff_ids" "$MAP" "$SRC_GFF" > "$REN_GFF" || true
  if [ ! -s "$REN_GFF" ]; then
    echo "WARNING: map_gff_ids produced empty file. Falling back to copy SRC_GFF as renamed."
    cp -f "$SRC_GFF" "$REN_GFF"
  fi
fi

echo "Check mRNA lines & ATML IDs in REN_GFF:"
grep -m3 -P '\tmRNA\t' "$REN_GFF" || true
grep -m3 -o 'ID=ATML[0-9]\{7\}-R[A-Z]' "$REN_GFF" || echo "Note: ATML IDs not visible in first hits (may still be present)."

echo "== Normalize & rename FASTA headers to $PREFIX IDs =="
# Build mapping: if missing, build from REN_GFF to stay consistent
if [ ! -s "$MAP" ]; then
  echo "id.map missing; creating from REN_GFF…"
  "$MAKERBIN/maker_map_ids" --prefix "$PREFIX" --justify 7 "$REN_GFF" > "$MAP"
fi

# AWK helpers: normalize header token to map key; then map to new ID
awk_norm='
  function norm(h,   x){
    x=h
    sub(/^>/,"",x)
    sub(/[[:space:]].*$/,"",x)
    sub(/[:|]-?protein.*/,"",x)
    sub(/[:|]-?cds.*/,"",x)
    return x
  }
'
awk_map='
  BEGIN{ FS="\t"; }
  FNR==NR { m[$1]=$2; next }
  /^>/ { base=norm($0); if(base in m){ print ">" m[base]; } else { print $0; } next }
  { print }
'

awk -v OFS="\t" "$awk_norm $awk_map" "$MAP" "$PROT_IN" > "$REN_PROT"
awk -v OFS="\t" "$awk_norm $awk_map" "$MAP" "$TX_IN"   > "$REN_TX"

[ -s "$REN_PROT" ] || { echo "ERROR: proteins.renamed.fasta is empty"; exit 4; }
[ -s "$REN_TX" ]   || { echo "ERROR: transcripts.renamed.fasta is empty"; exit 4; }

echo "== Quick stats =="
echo "mRNAs in SRC_GFF:" $(grep -P '\tmRNA\t' "$SRC_GFF" | wc -l)
echo "mRNAs in REN_GFF:" $(grep -P '\tmRNA\t' "$REN_GFF" | wc -l)
echo "proteins.renamed entries:" $(grep -c '^>' "$REN_PROT")
echo "transcripts.renamed entries:" $(grep -c '^>' "$REN_TX")
echo "Example protein header:" $(grep -m1 '^>' "$REN_PROT" || true)

echo "DONE."
