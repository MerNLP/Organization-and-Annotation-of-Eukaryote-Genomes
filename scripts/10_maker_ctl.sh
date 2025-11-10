#!/usr/bin/env bash
#SBATCH --job-name=maker_ctl
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --time=00:05:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/10_maker_ctl_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/10_maker_ctl_%j.e
set -euo pipefail

WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation"
COURSE="/data/courses/assembly-annotation-course/CDS_annotation"
CONTAINER="${COURSE}/containers/MAKER_3.01.03.sif"

mkdir -p "${WORKDIR}/maker"
cd "${WORKDIR}/maker"

# Find a container runner on the compute node
RUNNER="$(command -v apptainer || true)"
if [[ -z "${RUNNER}" && -x /usr/bin/apptainer ]]; then RUNNER=/usr/bin/apptainer; fi
if [[ -z "${RUNNER}" ]]; then RUNNER="$(command -v singularity || true)"; fi
if [[ -z "${RUNNER}" && -x /usr/bin/singularity ]]; then RUNNER=/usr/bin/singularity; fi
if [[ -z "${RUNNER}" ]]; then
  echo "ERROR: apptainer/singularity not found on compute node PATH." >&2
  exit 1
fi

# Create MAKER control files in ./maker
"$RUNNER" exec --bind "/data/users/mlawrence" "$CONTAINER" maker -CTL
echo "Generated: maker_opts.ctl  maker_bopts.ctl  maker_exe.ctl  maker_evm.ctl"
