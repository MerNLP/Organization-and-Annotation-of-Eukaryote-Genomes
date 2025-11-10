#!/usr/bin/env bash
#SBATCH --job-name=maker_mpi
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=50
#SBATCH --mem=64G
#SBATCH --time=4-00:00:00
#SBATCH --partition=pibu_el8
#SBATCH --output=/data/users/mlawrence/eukaryote_genome_annotation/logs/11_maker_run_%j.o
#SBATCH --error=/data/users/mlawrence/eukaryote_genome_annotation/logs/11_maker_run_%j.e
set -euo pipefail

# Paths
WORKDIR="/data/users/mlawrence/eukaryote_genome_annotation/maker"
CONTAINER="/data/courses/assembly-annotation-course/CDS_annotation/containers/MAKER_3.01.03.sif"

# MPI (IBU)
module load OpenMPI/4.1.1-GCC-10.3.0 2>/dev/null || true

cd "$WORKDIR"

# Find container runner on the compute node
RUNNER="$(command -v apptainer || true)"
if [[ -z "$RUNNER" && -x /usr/bin/apptainer ]]; then RUNNER=/usr/bin/apptainer; fi
if [[ -z "$RUNNER" ]]; then RUNNER="$(command -v singularity || true)"; fi
if [[ -z "$RUNNER" && -x /usr/bin/singularity ]]; then RUNNER=/usr/bin/singularity; fi
if [[ -z "$RUNNER" ]]; then
  echo "ERROR: apptainer/singularity not found on compute node PATH." >&2
  exit 1
fi

# Run MAKER (reads maker_opts.ctl etc. from $WORKDIR)
mpiexec --oversubscribe -n 50 "$RUNNER" exec \
  "$CONTAINER" \
  maker -mpi maker_opts.ctl maker_bopts.ctl maker_evm.ctl maker_exe.ctl
