#!/bin/bash
# Download the pilot runs from SRA as paired, compressed FASTQ files.
#
# Input:  data/metadata/pilot_runs.txt            (one Run per line)
#         data/metadata/pilot_expected_spots.csv  (columns: Run, Spot)
# Output: ~/acne-pilot-data/<RUN>/<RUN>_1.fastq.gz and <RUN>_2.fastq.gz
#         ~/acne-pilot-data/<RUN>.done            (empty marker: run finished and verified)
#
# Usage (from WSL, at the repo root):
#   conda activate pilot
#   bash workflow/wsl/01_download_pilot.sh


# ---- Paths ----
# Script and metadata live in the repo (Windows side, tracked by Git).
# FASTQ data lives on the Linux side: much faster than /mnt/c and kept out of Git.
# REPO_DIR is found from the script's own location (like here() in R),
# so no personal path is written in the file:
# this script is in <repo>/workflow/wsl/, so the repo root is two folders up.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUNS_FILE="$REPO_DIR/data/metadata/pilot_runs.txt"
EXPECTED_FILE="$REPO_DIR/data/metadata/pilot_expected_spots.csv"
DATA_DIR="$HOME/acne-pilot-data"


# ---- Prepare ----
# -p: no error if the folder already exists (the script can be run many times)
mkdir -p "$DATA_DIR"

# Stop early if an input file is missing
for file in "$RUNS_FILE" "$EXPECTED_FILE"; do
  if [ ! -f "$file" ]; then
    echo "ERROR: file not found: $file" >&2
    exit 1
  fi
done


# ---- Read the list of runs ----
# The metadata files are written by R on Windows, so lines end in \r\n (CRLF).
# tr -d '\r' removes the \r; otherwise every Run ID would carry a hidden \r
# and prefetch would reject it.
# mapfile -t stores one line per element in the array RUNS.
mapfile -t RUNS < <(tr -d '\r' < "$RUNS_FILE")

# Check: 15 runs
if [ "${#RUNS[@]}" -ne 15 ]; then
  echo "ERROR: expected 15 runs, found ${#RUNS[@]}" >&2
  exit 1
fi


# ---- Expected spots ----
# Returns the expected spots of one run (column 2 of the CSV).
# Usage: get_expected_spots SRR20028132
get_expected_spots() {
  tr -d '\r' < "$EXPECTED_FILE" | grep "^$1," | cut -d, -f2
}


# ---- Optional: process only some runs ----
# Without arguments the script processes the 15 runs.
# With arguments it processes only those (useful for testing), e.g.:
#   bash workflow/wsl/01_download_pilot.sh SRR20028087
if [ "$#" -gt 0 ]; then
  RUNS=("$@")
fi


# ---- Check inputs before downloading anything ----
# The SRA tools come from the conda env "pilot"
if ! command -v prefetch > /dev/null || ! command -v fasterq-dump > /dev/null; then
  echo "ERROR: prefetch/fasterq-dump not found. Run: conda activate pilot" >&2
  exit 1
fi

# Every run must have an expected spots value (used later to check read counts)
for run in "${RUNS[@]}"; do
  if [ -z "$(get_expected_spots "$run")" ]; then
    echo "ERROR: no expected spots for $run" >&2
    exit 1
  fi
done


# ---- Process each run ----
# A failed run is recorded and the script moves on to the next one.
FAILED=()

for run in "${RUNS[@]}"; do
  run_dir="$DATA_DIR/$run"
  echo "==== $run ===="

  # a. Skip runs already finished and verified
  if [ -f "$DATA_DIR/$run.done" ]; then
    echo "Already done, skipping"
    continue
  fi

  # b. Download the .sra into $DATA_DIR/<RUN>/
  #    "if ! command" = if the command fails (exit code != 0)
  if ! prefetch "$run" -O "$DATA_DIR"; then
    FAILED+=("$run (prefetch)")
    continue
  fi

  # c. Convert the .sra into paired FASTQ files
  #    -S: split R1/R2 into <RUN>_1.fastq and <RUN>_2.fastq
  #    -O: output folder
  #    -t: temporary files folder; without it they go to the current folder,
  #        which can be /mnt/c (slow) when the script is run from the repo
  #    -f: overwrite FASTQ left by a previous run that stopped halfway
  if ! fasterq-dump -S -f -O "$run_dir" -t "$run_dir" "$run_dir"; then
    FAILED+=("$run (fasterq-dump)")
    continue
  fi

  # d-f. Compress, check and clean up: next step
  echo "Converted to FASTQ (compression and checks: not implemented yet)"
done


# ---- Summary ----
echo
if [ "${#FAILED[@]}" -eq 0 ]; then
  echo "All runs processed without errors"
else
  echo "Failed runs:"
  printf '  %s\n' "${FAILED[@]}"
  exit 1
fi
