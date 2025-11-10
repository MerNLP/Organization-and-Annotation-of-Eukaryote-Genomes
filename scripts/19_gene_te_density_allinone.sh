#!/bin/bash
#SBATCH --job-name=gene_te_density_fix
#SBATCH --partition=pibu_el8
#SBATCH --cpus-per-task=2
#SBATCH --mem=6G
#SBATCH --time=00:15:00
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
set -euo pipefail

GENOME="/data/users/mlawrence/assembly_annotation_course/assemblies/hifiasm/hifiasm.p_ctg.fa"
GFF_GENE="maker/final/assembly.all.maker.renamed.iprscan.gff"
GFF_TE="results/EDTA_annotation/hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3"
BIN=100000

OUTDIR="results/figures"
TMP="results/tmp"
PDF="${OUTDIR}/05_gene_vs_te_density_100kb.pdf"

mkdir -p "$OUTDIR" "$TMP"

module load SAMtools/1.13-GCC-10.3.0 2>/dev/null || true
module load BEDTools/2.30.0-GCC-10.3.0 2>/dev/null || true
module load R/4.1.0-foss-2021a 2>/dev/null || true

[ -s "$GENOME" ] || { echo "Missing $GENOME"; exit 2; }
[ -s "$GFF_GENE" ] || { echo "Missing $GFF_GENE"; exit 2; }
[ -s "$GFF_TE" ] || { echo "Missing $GFF_TE"; exit 2; }

# 1) genome sizes / windows
[ -s "${GENOME}.fai" ] || samtools faidx "$GENOME"
cut -f1,2 "${GENOME}.fai" > "${TMP}/genome.sizes"
bedtools makewindows -g "${TMP}/genome.sizes" -w $BIN > "${TMP}/windows.${BIN}.bed"

# 2) features → BED
awk -F'\t' '$0!~/^#/ && $3=="mRNA"{print $1"\t"$4-1"\t"$5}' "$GFF_GENE" > "${TMP}/mrna.bed"
awk -F'\t' '$0!~/^#/{print $1"\t"$4-1"\t"$5}' "$GFF_TE" > "${TMP}/te.bed"

# 3) coverage WITHOUT -mean → fraction covered is column 7
bedtools coverage -a "${TMP}/windows.${BIN}.bed" -b "${TMP}/mrna.bed" > "${TMP}/gene_cov.tsv"
bedtools coverage -a "${TMP}/windows.${BIN}.bed" -b "${TMP}/te.bed"   > "${TMP}/te_cov.tsv"

# sanity print headers of a few rows
head -n 3 "${TMP}/gene_cov.tsv"
head -n 3 "${TMP}/te_cov.tsv"

# 4) extract fraction column ($7) → tidy TSVs
awk '{print $1"\t"$2"\t"$3"\t"$7}' "${TMP}/gene_cov.tsv" > "${TMP}/gene_density.tsv"
awk '{print $1"\t"$2"\t"$3"\t"$7}' "${TMP}/te_cov.tsv"   > "${TMP}/te_density.tsv"

# 5) plot unscaled so real variation is visible
Rscript - <<'RS'
genes <- read.table("results/tmp/gene_density.tsv", sep="\t", header=FALSE,
                    col.names=c("contig","start","end","gene_frac"))
tes   <- read.table("results/tmp/te_density.tsv",   sep="\t", header=FALSE,
                    col.names=c("contig","start","end","te_frac"))
df <- merge(genes, tes, by=c("contig","start","end"), all=TRUE)
df[is.na(df)] <- 0

# order contigs by length proxy
ord <- aggregate(end ~ contig, df, max)
ord <- ord[order(-ord$end), ]
df$contig <- factor(df$contig, levels=ord$contig)

pdf("results/figures/05_gene_vs_te_density_100kb.pdf", width=10, height=6)
par(mfrow=c(2,1), mar=c(4,4,2,1))
plot(df$gene_frac, type="l", xlab="Windows (100 kb)", ylab="Gene fraction covered",
     main="Gene density (fraction of window covered)")
plot(df$te_frac, type="l", xlab="Windows (100 kb)", ylab="TE fraction covered",
     main="TE density (fraction of window covered)")
dev.off()

# correlation (pooled windows, excluding all-zero windows)
nz <- (df$gene_frac + df$te_frac) > 0
cor_val <- if (any(nz)) cor(df$gene_frac[nz], df$te_frac[nz]) else NA
writeLines(sprintf("Pearson r (gene vs TE): %s", cor_val),
           "results/figures/05_gene_vs_te_density_100kb.corr.txt")
RS

echo "Wrote: $PDF"
ls -lh "$PDF"
