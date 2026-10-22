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


# ---- Check inputs (temporary: replaced by the download loop in the next step) ----
# Print each run with its expected spots; stop if one has no value.
for run in "${RUNS[@]}"; do
  expected=$(get_expected_spots "$run")
  if [ -z "$expected" ]; then
    echo "ERROR: no expected spots for $run" >&2
    exit 1
  fi
  echo "$run $expected"
done
