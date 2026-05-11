#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog2_vecintrin"
HEADER="$PROG_DIR/CS149intrin.h"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog2/q2"
CSV="$OUT_DIR/vector_width_sweep.csv"

mkdir -p "$OUT_DIR"

orig_header="$(mktemp)"
cp "$HEADER" "$orig_header"
restore_header() {
  cp "$orig_header" "$HEADER"
  rm -f "$orig_header"
}
trap restore_header EXIT

printf "vector_width,total_vector_instructions,vector_utilization,utilized_lanes,total_lanes,required_passed\n" > "$CSV"

for width in 2 4 8 16; do
  sed -i -E "s/^#define VECTOR_WIDTH .*/#define VECTOR_WIDTH ${width}/" "$HEADER"

  make -C "$PROG_DIR" clean >/dev/null
  make -C "$PROG_DIR" >/dev/null

  log_file="$OUT_DIR/vector_width_${width}.log"
  (cd "$PROG_DIR" && ./myexp -s 10000) > "$log_file"

  total_instructions="$(awk -F: '/Total Vector Instructions/ {gsub(/ /, "", $2); print $2}' "$log_file")"
  utilization="$(awk -F: '/Vector Utilization/ {gsub(/[% ]/, "", $2); print $2}' "$log_file")"
  utilized_lanes="$(awk -F: '/Utilized Vector Lanes/ {gsub(/ /, "", $2); print $2}' "$log_file")"
  total_lanes="$(awk -F: '/Total Vector Lanes/ {gsub(/ /, "", $2); print $2}' "$log_file")"

  if grep -q "Results matched with answer!" "$log_file"; then
    required_passed="yes"
  else
    required_passed="no"
  fi

  printf "%s,%s,%s,%s,%s,%s\n" \
    "$width" \
    "$total_instructions" \
    "$utilization" \
    "$utilized_lanes" \
    "$total_lanes" \
    "$required_passed" >> "$CSV"
done

cat "$CSV"
