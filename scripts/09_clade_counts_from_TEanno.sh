#!/usr/bin/env bash
#SBATCH --job-name=clade_from_TEanno
#SBATCH --cpus-per-task=2
#SBATCH --mem=6G
#SBATCH --time=00:30:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/clade_from_TEanno_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/clade_from_TEanno_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
EDTA_OUT="${WORKDIR}/results/EDTA_annotation"
TS_OUT="${WORKDIR}/results/TEsorter_all"
FIGDIR="${WORKDIR}/results/figures"
mkdir -p "${FIGDIR}"

GFF="${EDTA_OUT}/hifiasm.p_ctg.fa.mod.EDTA.TEanno.gff3"
COP="${TS_OUT}/Copia_sequences.fa.rexdb-plant.cls.tsv"
GYP="${TS_OUT}/Gypsy_sequences.fa.rexdb-plant.cls.tsv"
OUT="${TS_OUT}/Copia_Gypsy_clade_counts_from_TEanno.tsv"

for f in "$GFF" "$COP" "$GYP"; do
  [[ -s "$f" ]] || { echo "[ERR] Missing file: $f" >&2; exit 1; }
done

# build TE -> Clade map from TEsorter (Copia + Gypsy)
awk -F'\t' '
  BEGIN{OFS="\t"}
  NR==FNR {
    if (FNR>1 && $0!="") {
      te=$1; cl=$4
      sub(/#.*/,"",te)
      sub(/_INT$/,"",te)
      if(cl=="") cl="Unclassified"
      map[te]=cl
    }
    next
  }
  FNR>1 && $0!="" {
    te=$1; cl=$4
    sub(/#.*/,"",te)
    sub(/_INT$/,"",te)
    if(cl=="") cl="Unclassified"
    map[te]=cl
  }
  END{ for(k in map) print k, map[k] }
' "$COP" "$GYP" \
| sort -u > "${TS_OUT}/TE_to_Clade.map.tsv"

#join map to final TEanno and count elements per clade for Copia/Gypsy
awk -v MAP="${TS_OUT}/TE_to_Clade.map.tsv" '
  BEGIN{
    FS=OFS="\t"
    while((getline < MAP)>0){ te=$1; cl=$2; te2cl[te]=cl }
    close(MAP)
    print "Superfamily","Clade","Count"
  }
  $0 ~ /^#/ { next }  # skip comments
  NF>=9 {
    type=$3; attrs=$9

    # accept more feature types
    if (type!="transposable_element" && type!="repeat_region" && type!="LTR_retrotransposon") next

    # Superfamily from Superfamily= or derive from Classification=
    sf=""
    if (match(attrs, /(^|;)Superfamily=[^;]+/, m)){ sf=m[0]; sub(/(^|;)Superfamily=/,"",sf) }
    if (sf=="") {
      cls=""
      if (match(attrs, /(^|;)Classification=[^;]+/, c)){ cls=c[0]; sub(/(^|;)Classification=/,"",cls) }
      # Derive superfamily from common tokens
      if (cls ~ /(^|[^A-Za-z])(Copia|RLC)([^A-Za-z]|$)/i) sf="Copia"
      else if (cls ~ /(^|[^A-Za-z])(Gypsy|RLG)([^A-Za-z]|$)/i) sf="Gypsy"
    }
    if (sf!="Copia" && sf!="Gypsy") next

    # TE name from Name= (fallback Target= / Classification=)
    name=""
    if (match(attrs, /(^|;)Name=[^;]+/, n)) { name=n[0]; sub(/(^|;)Name=/,"",name) }
    if (name=="") {
      if (match(attrs, /(^|;)Target=[^;]+/, t)) { name=t[0]; sub(/(^|;)Target=/,"",name) }
      else if (match(attrs, /(^|;)Classification=[^;]+/, c2)) { name=c2[0]; sub(/(^|;)Classification=/,"",name) }
    }
    sub(/:.*/,"",name)
    sub(/_LTR$/,"",name); sub(/_INT$/,"",name)

    cl = (name in te2cl ? te2cl[name] : "Unclassified")
    key = sf "\t" cl
    cnt[key]++
  }
  END{
    for(k in cnt){
      split(k,a,"\t")
      print a[1], a[2], cnt[k]
    }
  }
' "$GFF" \
| sort -t $'\t' -k1,1 -k3,3nr > "$OUT"

echo "[OK] Wrote: $OUT"
lines=$(wc -l < "$OUT" || echo 0)
if [[ "$lines" -le 1 ]]; then
  echo "[WARN] No Copia/Gypsy elements found after parsing TEanno; skipping plot."
  exit 0
fi

# --- plot (headless-safe) ---
export R_LIBS_USER="${WORKDIR}/.Rlib"
module load R 2>/dev/null || true

Rscript - <<'RSCRIPT'
suppressPackageStartupMessages({
  if (!requireNamespace("data.table", quietly=TRUE)) install.packages("data.table", repos="https://cloud.r-project.org")
  if (!requireNamespace("ggplot2",   quietly=TRUE)) install.packages("ggplot2",   repos="https://cloud.r-project.org")
  if (!requireNamespace("ragg",      quietly=TRUE)) install.packages("ragg",      repos="https://cloud.r-project.org")
})

library(data.table); library(ggplot2)

workdir <- Sys.getenv("WORKDIR", unset="/data/users/mlawrence/eukaryote_genome_annotation")
ts_out  <- file.path(workdir, "results/TEsorter_all")
figdir  <- file.path(workdir, "results/figures")

tab <- fread(file.path(ts_out, "Copia_Gypsy_clade_counts_from_TEanno.tsv"), sep="\t", header=TRUE)
if (nrow(tab) == 0L) {
  cat("[WARN] Empty table; not plotting.\n")
  q(save="no")  # exit cleanly
}

setnames(tab, c("Superfamily","Clade","Count"))
tab[is.na(Clade) | Clade=="", Clade := "Unclassified"]

# order clades within each superfamily by count
tab[, Clade := factor(Clade, levels = tab[order(Superfamily, -Count), unique(Clade)])]

p <- ggplot(tab, aes(x = Count, y = Clade)) +
  geom_col() +
  facet_wrap(~ Superfamily, scales = "free_y", ncol = 1) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Copia & Gypsy clade counts (final TEanno joined with TEsorter)",
    x = "Elements (count)", y = "Clade"
  )

png_file <- file.path(figdir, "04_clade_counts_from_TEanno.png")
pdf_file <- file.path(figdir, "04_clade_counts_from_TEanno.pdf")

ggsave(pdf_file, p, width=8, height=10, units="in")
ragg::agg_png(png_file, width=8, height=10, units="in", res=120); print(p); dev.off()

cat("[OK] Wrote:", pdf_file, "and", png_file, "\n")
RSCRIPT
