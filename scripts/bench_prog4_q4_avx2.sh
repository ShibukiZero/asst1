#!/usr/bin/env bash
# Benchmark Program 4 manual AVX2 implementation against ISPC.

set -euo pipefail

RUNS=${RUNS:-5}
COOLDOWN=${COOLDOWN:-60}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog4_sqrt"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog4/q4_avx2"
SUMMARY="$OUT_DIR/summary.csv"
MEANS="$OUT_DIR/means.csv"
RAW_LOG="$OUT_DIR/raw.log"

mkdir -p "$OUT_DIR"

cd "$PROG_DIR"
make clean >/dev/null
make >/dev/null

printf "run,serial_ms,ispc_ms,avx2_ms,task_ms,ispc_speedup,avx2_speedup,avx2_over_ispc,task_speedup\n" > "$SUMMARY"
: > "$RAW_LOG"

{
  echo "=== Program 4 Q4 AVX2 benchmark: cooldown ${COOLDOWN}s + ${RUNS} measured invocations ==="
  echo "Input: starter pseudo-random values in [0.001, 2.999]"
} | tee -a "$RAW_LOG"

for run in $(seq 1 "$RUNS"); do
  echo "--- invocation ${run} (cooldown ${COOLDOWN}s) ---" | tee -a "$RAW_LOG"
  sleep "$COOLDOWN"

  out=$(./sqrt)
  echo "$out" | tee -a "$RAW_LOG" >/dev/null

  serial_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '1p')
  ispc_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '2p')
  avx2_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '3p')
  task_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '4p')
  ispc_speedup=$(echo "$out" | awk -F'[()]' '/speedup from ISPC/ {gsub(/x speedup from ISPC/, "", $2); print $2; exit}')
  avx2_speedup=$(echo "$out" | awk -F'[()]' '/speedup from AVX2/ {gsub(/x speedup from AVX2/, "", $2); print $2; exit}')
  avx2_over_ispc=$(awk -v avx2="$avx2_ms" -v ispc="$ispc_ms" 'BEGIN { printf "%.3f", avx2 / ispc }')
  task_speedup=$(echo "$out" | awk -F'[()]' '/speedup from task ISPC/ {gsub(/x speedup from task ISPC/, "", $2); print $2}')

  printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
    "$run" "$serial_ms" "$ispc_ms" "$avx2_ms" "$task_ms" \
    "$ispc_speedup" "$avx2_speedup" "$avx2_over_ispc" "$task_speedup" >> "$SUMMARY"
done

python3 - "$SUMMARY" "$MEANS" <<'PY'
import csv
import sys

src, dest = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(src, newline="")))

fields = [
    "runs",
    "mean_serial_ms",
    "mean_ispc_ms",
    "mean_avx2_ms",
    "mean_task_ms",
    "mean_ispc_speedup",
    "mean_avx2_speedup",
    "mean_avx2_over_ispc",
    "mean_task_speedup",
]

def mean(key):
    vals = [float(row[key]) for row in rows]
    return f"{sum(vals) / len(vals):.3f}"

with open(dest, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    writer.writerow({
        "runs": len(rows),
        "mean_serial_ms": mean("serial_ms"),
        "mean_ispc_ms": mean("ispc_ms"),
        "mean_avx2_ms": mean("avx2_ms"),
        "mean_task_ms": mean("task_ms"),
        "mean_ispc_speedup": mean("ispc_speedup"),
        "mean_avx2_speedup": mean("avx2_speedup"),
        "mean_avx2_over_ispc": mean("avx2_over_ispc"),
        "mean_task_speedup": mean("task_speedup"),
    })
PY

cat "$MEANS"
