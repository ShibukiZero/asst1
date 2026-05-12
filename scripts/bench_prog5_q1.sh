#!/usr/bin/env bash
# Benchmark Program 5 saxpy for Q1.

set -euo pipefail

RUNS=${RUNS:-5}
COOLDOWN=${COOLDOWN:-60}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog5_saxpy"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog5/q1_baseline"
SUMMARY="$OUT_DIR/summary.csv"
MEANS="$OUT_DIR/means.csv"
RAW_LOG="$OUT_DIR/raw.log"

mkdir -p "$OUT_DIR"

cd "$PROG_DIR"
make clean >/dev/null
make >/dev/null

printf "run,ispc_ms,ispc_gbps,ispc_gflops,task_ms,task_gbps,task_gflops,task_speedup\n" > "$SUMMARY"
: > "$RAW_LOG"

{
  echo "=== Program 5 Q1 saxpy baseline: cooldown ${COOLDOWN}s + ${RUNS} measured invocations ==="
  echo "Input: N = 20,000,000, arrayX[i] = i, arrayY[i] = i, scale = 2"
} | tee -a "$RAW_LOG"

for run in $(seq 1 "$RUNS"); do
  echo "--- invocation ${run} (cooldown ${COOLDOWN}s) ---" | tee -a "$RAW_LOG"
  sleep "$COOLDOWN"

  out=$(./saxpy)
  echo "$out" | tee -a "$RAW_LOG" >/dev/null

  ispc_ms=$(echo "$out" | awk -F'[][]' '/saxpy ispc/ {print $4; exit}')
  ispc_gbps=$(echo "$out" | awk -F'[][]' '/saxpy ispc/ {print $6; exit}')
  ispc_gflops=$(echo "$out" | awk -F'[][]' '/saxpy ispc/ {print $8; exit}')
  task_ms=$(echo "$out" | awk -F'[][]' '/saxpy task ispc/ {print $4; exit}')
  task_gbps=$(echo "$out" | awk -F'[][]' '/saxpy task ispc/ {print $6; exit}')
  task_gflops=$(echo "$out" | awk -F'[][]' '/saxpy task ispc/ {print $8; exit}')
  task_speedup=$(echo "$out" | awk -F'[()]' '/speedup from use of tasks/ {gsub(/x speedup from use of tasks/, "", $2); print $2; exit}')

  printf "%s,%s,%s,%s,%s,%s,%s,%s\n" \
    "$run" "$ispc_ms" "$ispc_gbps" "$ispc_gflops" \
    "$task_ms" "$task_gbps" "$task_gflops" "$task_speedup" >> "$SUMMARY"
done

python3 - "$SUMMARY" "$MEANS" <<'PY'
import csv
import sys

src, dest = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(src, newline="")))

fields = [
    "runs",
    "mean_ispc_ms",
    "mean_ispc_gbps",
    "mean_ispc_gflops",
    "mean_task_ms",
    "mean_task_gbps",
    "mean_task_gflops",
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
        "mean_ispc_ms": mean("ispc_ms"),
        "mean_ispc_gbps": mean("ispc_gbps"),
        "mean_ispc_gflops": mean("ispc_gflops"),
        "mean_task_ms": mean("task_ms"),
        "mean_task_gbps": mean("task_gbps"),
        "mean_task_gflops": mean("task_gflops"),
        "mean_task_speedup": mean("task_speedup"),
    })
PY

cat "$MEANS"
