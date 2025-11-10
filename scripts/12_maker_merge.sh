#!/usr/bin/env bash
#SBATCH --job-name=MAKER_merge
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=06:00:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/12_maker_merge_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/12_maker_merge_%j.e

set -euo pipefail
WORKDIR=/data/users/mlawrence/eukaryote_genome_annotation
MAKERDIR=$WORKDIR/maker
CONTAINER=/data/courses/assembly-annotation-course/CDS_annotation/containers/MAKER_3.01.03.sif

cd "$MAKERDIR"

# merge GFF3 from all chunks
apptainer exec --bind /data/users/mlawrence,/data/courses/assembly-annotation-course \
  "$CONTAINER" \
  gff3_merge -s -n -d hifiasm.p_ctg.maker.output/hifiasm.p_ctg_master_datastore_index.log \
  -o assembly.all.maker.gff

# also produce a no-sequence GFF (smaller)
apptainer exec --bind /data/users/mlawrence,/data/courses/assembly-annotation-course \
  "$CONTAINER" \
  gff3_merge -n -d hifiasm.p_ctg.maker.output/hifiasm.p_ctg_master_datastore_index.log \
  -o assembly.all.maker.noseq.gff

# merge transcripts & proteins
apptainer exec --bind /data/users/mlawrence,/data/courses/assembly-annotation-course \
  "$CONTAINER" \
  fasta_merge -d hifiasm.p_ctg.maker.output/hifiasm.p_ctg_master_datastore_index.log

echo "Done. Outputs should include:"
echo " - maker/assembly.all.maker.gff"
echo " - maker/assembly.all.maker.noseq.gff"
echo " - maker/assembly.all.maker.transcripts.fasta"
echo " - maker/assembly.all.maker.proteins.fasta"
