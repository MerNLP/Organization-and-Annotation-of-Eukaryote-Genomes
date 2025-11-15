#!/usr/bin/env bash
#SBATCH --job-name=func_titles_v2
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=02:00:00
#SBATCH --partition=pibu_el8
#SBATCH --mail-user=merlyne.lawrence@students.unibe.ch
#SBATCH --mail-type=END,FAIL
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/func_titles_v2_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/func_titles_v2_%j.e

set -euo pipefail
echo "=== NO BLASTDBCMD ==="

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
FINAL="$WORKDIR/maker/final"
BEST="$WORKDIR/results/uniprot/maker_vs_uniprot.stitle.best.tsv"

[[ -s "$BEST" ]] || { echo "[ERR] Missing $BEST; run 20b_uniprot_blast_with_titles.sh"; exit 2; }

# autodetect inputs
if [[ -s "$FINAL/proteins.renamed.fasta" ]]; then
  FAA_IN="$FINAL/proteins.renamed.fasta"
elif [[ -s "$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta" ]]; then
  FAA_IN="$FINAL/hifiasm.p_ctg.all.maker.proteins.fasta.renamed.fasta"
else
  echo "[ERR] Missing proteins FASTA in $FINAL"; exit 3
fi

if [[ -s "$FINAL/assembly.all.maker.noseq.gff.renamed.gff" ]]; then
  GFF_IN="$FINAL/assembly.all.maker.noseq.gff.renamed.gff"
elif [[ -s "$FINAL/assembly.all.maker.noseq.renamed.gff" ]]; then
  GFF_IN="$FINAL/assembly.all.maker.noseq.renamed.gff"
else
  echo "[ERR] Missing renamed noseq GFF in $FINAL"; exit 4
fi

FAA_OUT="$FINAL/$(basename "$FAA_IN").Uniprot"
GFF_OUT="$FINAL/$(basename "${GFF_IN%.gff}").Uniprot.gff3"

# Build qid -> acc,title map from the titles BLAST (columns: qid sacc stitle evalue bitscore)
awk -F'\t' 'BEGIN{OFS="\t"}{print $1,$2,$3}' "$BEST" > "$BEST.map"

# Annotate FASTA headers
awk -v MAP="$BEST.map" '
BEGIN{
  FS=OFS="\t";
  while((getline < MAP)>0){ id=$1; acc=$2; title=$3; ann[id]=" UniProt="acc" Note="title }
  close(MAP)
}
(/^>/){
  line=$0; sub(/^>/,"",line);
  split(line,a,/[\t ]/); id=a[1];
  if(id in ann){ print ">" id ann[id] } else { print ">" line }
  next
}
{ print }
' "$FAA_IN" > "$FAA_OUT"

# Annotate GFF (mRNA features)
awk -v MAP="$BEST.map" -F'\t' '
BEGIN{
  OFS="\t";
  while((getline < MAP)>0){ id=$1; acc=$2; title=$3; gsub(/;/," ",title); macc[id]=acc; mnote[id]=title }
  close(MAP)
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

echo "[DONE]"
echo "  FASTA annotated : $FAA_OUT"
echo "  GFF3 annotated  : $GFF_OUT"
