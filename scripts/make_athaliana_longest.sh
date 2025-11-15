#!/usr/bin/env bash
#SBATCH --job-name=ath_longest
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=00:15:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/make_athaliana_longest_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/make_athaliana_longest_%j.e

set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
IN="$WORKDIR/maker/final/proteins.renamed.fasta.Uniprot"
OUT="$WORKDIR/genespace_input/peptide/Athaliana.fa"

echo "=== Building longest-per-gene Athaliana FASTA for GENESPACE ==="
echo "[IN ] $IN"
echo "[OUT] $OUT"

# If your cluster needs a Python module, uncomment and adjust:
# module load Python/3.11.3-gompi-2023a

python3 - "$IN" "$OUT" << 'PY'
import sys

in_f, out_f = sys.argv[1], sys.argv[2]

def read_fasta(path):
    header = None
    seq = []
    with open(path) as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            if line.startswith(">"):
                if header is not None:
                    yield header, "".join(seq)
                header = line[1:]
                seq = []
            else:
                seq.append(line)
    if header is not None:
        yield header, "".join(seq)

best = {}  # gene -> (length, seq)

for header, seq in read_fasta(in_f):
    # Header like: ATML0028857-RA UniProt=...
    first = header.split()[0]
    gene = first.split("-")[0]   # ATML0028857-RA -> ATML0028857
    L = len(seq)
    if gene not in best or L > best[gene][0]:
        best[gene] = (L, seq)

with open(out_f, "w") as out:
    for gene, (L, seq) in best.items():
        out.write(f">{gene}\n")
        for i in range(0, len(seq), 60):
            out.write(seq[i:i+60] + "\n")
PY

echo "[DONE] Wrote longest-per-gene FASTA: $OUT"
