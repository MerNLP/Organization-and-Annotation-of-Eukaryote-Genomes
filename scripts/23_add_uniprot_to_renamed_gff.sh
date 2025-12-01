#!/usr/bin/env bash
#SBATCH --job-name=add_uniprot_to_renamed_gff
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/add_uniprot_to_renamed_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/add_uniprot_to_renamed_%j.e

set -euo pipefail
echo "=== Step 23: Add UniProt tags to renamed GFF ==="

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
FINAL="$WORKDIR/maker/final"
BEST="$WORKDIR/results/uniprot/maker_vs_uniprot.stitle.best.tsv"

# input checks 
[[ -s "$BEST" ]] || { echo "[ERR] Missing $BEST (run 20b_uniprot_blast_with_titles.sh first)"; exit 2; }

GFF_IN="$FINAL/assembly.all.maker.noseq.renamed.gff"
GFF_OUT="$FINAL/assembly.all.maker.noseq.renamed.Uniprot.gff3"

[[ -s "$GFF_IN" ]] || { echo "[ERR] Missing input GFF: $GFF_IN"; exit 3; }

echo "[INFO] Input GFF : $GFF_IN"
echo "[INFO] Output GFF: $GFF_OUT"
echo "[INFO] UniProt hits: $BEST"

# build qid→acc,title map 
awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3}' "$BEST" > "$BEST.map"
echo "[INFO] Map lines: $(wc -l < "$BEST.map")"

# annotate mRNA features 
awk -v MAP="$BEST.map" -F'\t' '
BEGIN{
  OFS="\t";
  while((getline < MAP)>0){
    id=$1; acc=$2; title=$3;
    gsub(/;/," ",title);
    macc[id]=acc; mnote[id]=title;
  }
  close(MAP);
}
{
  if($0 ~ /^#/ || NF<9){ print; next }
  if($3=="mRNA"){
    attr=$9; id="";
    n=split(attr,a,";");
    for(i=1;i<=n;i++){ if(a[i] ~ /^ID=/){ id=substr(a[i],4) } }
    if(id!="" && (id in macc)){
      if(attr !~ /Dbxref=UniProt:/){ attr=attr";Dbxref=UniProt:"macc[id] }
      if(attr !~ /(^|;)Note=/){ attr=attr";Note="mnote[id] }
      $9=attr; print; next
    }
  }
  print
}' "$GFF_IN" > "$GFF_OUT"

echo "[DONE] Annotated GFF written to $GFF_OUT"
echo "Annotated mRNAs: $(grep -c 'Dbxref=UniProt:' "$GFF_OUT")"
echo "Total mRNAs    : $(grep -c $'\tmRNA\t' "$GFF_OUT")"
