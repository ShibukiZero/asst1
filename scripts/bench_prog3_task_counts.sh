#!/usr/bin/env bash
# Sweep Program 3 ISPC task counts by temporarily editing mandelbrot.ispc.

set -euo pipefail

RUNS=${RUNS:-5}
COOLDOWN=${COOLDOWN:-10}
TASK_COUNTS=${TASK_COUNTS:-"2 4 8 16 25 40 50 80 100 160"}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog3_mandelbrot_ispc"
ISPC_FILE="$PROG_DIR/mandelbrot.ispc"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog3/task_count_sweep"
SUMMARY="$OUT_DIR/summary.csv"
MEANS="$OUT_DIR/means.csv"
RAW_LOG="$OUT_DIR/raw.log"

mkdir -p "$OUT_DIR"

orig_ispc="$(mktemp)"
cp "$ISPC_FILE" "$orig_ispc"
restore_ispc() {
  cp "$orig_ispc" "$ISPC_FILE"
  rm -f "$orig_ispc"
}
trap restore_ispc EXIT

printf "task_count,run,serial_ms,ispc_ms,task_ms,ispc_speedup,task_speedup,task_over_ispc\n" > "$SUMMARY"
: > "$RAW_LOG"

cd "$PROG_DIR"

for task_count in $TASK_COUNTS; do
  if (( 800 % task_count != 0 )); then
    echo "Skipping task_count=$task_count because 800 rows is not divisible by it" | tee -a "$RAW_LOG"
    continue
  fi

  cp "$orig_ispc" "$ISPC_FILE"
  sed -i -E "s/uniform int rowsPerTask = height \\/ [0-9]+;/uniform int rowsPerTask = height \\/ ${task_count};/" "$ISPC_FILE"
  sed -i -E "s/launch\\[[0-9]+\\]/launch[${task_count}]/" "$ISPC_FILE"
  sed -i -E "s/create [0-9]+ tasks/create ${task_count} tasks/" "$ISPC_FILE"

  make clean >/dev/null
  make >/dev/null

  {
    echo
    echo "=== task_count=${task_count}: cooldown ${COOLDOWN}s + ${RUNS} measured invocations ==="
  } | tee -a "$RAW_LOG"

  sleep "$COOLDOWN"

  for run in $(seq 1 "$RUNS"); do
    echo "--- task_count=${task_count} invocation ${run} ---" | tee -a "$RAW_LOG"
    out=$(./mandelbrot_ispc --tasks)
    echo "$out" | tee -a "$RAW_LOG" >/dev/null

    serial_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '1p')
    ispc_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '2p')
    task_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '3p')
    ispc_speedup=$(echo "$out" | awk -F'[()]' '/speedup from ISPC/ {gsub(/x speedup from ISPC/, "", $2); print $2; exit}')
    task_speedup=$(echo "$out" | awk -F'[()]' '/speedup from task ISPC/ {gsub(/x speedup from task ISPC/, "", $2); print $2}')
    task_over_ispc=$(awk -v ispc="$ispc_ms" -v task="$task_ms" 'BEGIN { printf "%.3f", ispc / task }')

    printf "%s,%s,%s,%s,%s,%s,%s,%s\n" \
      "$task_count" "$run" "$serial_ms" "$ispc_ms" "$task_ms" \
      "$ispc_speedup" "$task_speedup" "$task_over_ispc" >> "$SUMMARY"
  done
done

python3 - "$SUMMARY" "$MEANS" <<'PY'
import csv
import sys
from collections import defaultdict

src, dest = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(src, newline="")))
groups = defaultdict(list)
for row in rows:
    groups[int(row["task_count"])].append(row)

fields = [
    "task_count",
    "runs",
    "mean_serial_ms",
    "mean_ispc_ms",
    "mean_task_ms",
    "mean_ispc_speedup",
    "mean_task_speedup",
    "mean_task_over_ispc",
]

def mean(items, key):
    vals = [float(item[key]) for item in items if item[key] != ""]
    return f"{sum(vals) / len(vals):.3f}"

with open(dest, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    for task_count in sorted(groups):
        items = groups[task_count]
        writer.writerow({
            "task_count": task_count,
            "runs": len(items),
            "mean_serial_ms": mean(items, "serial_ms"),
            "mean_ispc_ms": mean(items, "ispc_ms"),
            "mean_task_ms": mean(items, "task_ms"),
            "mean_ispc_speedup": mean(items, "ispc_speedup"),
            "mean_task_speedup": mean(items, "task_speedup"),
            "mean_task_over_ispc": mean(items, "task_over_ispc"),
        })
PY

cat "$MEANS"
