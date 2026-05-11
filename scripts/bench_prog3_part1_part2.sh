#!/usr/bin/env bash
# Benchmark Program 3 Part 1 and starter Part 2 tasking.

set -euo pipefail

RUNS=${RUNS:-5}
COOLDOWN=${COOLDOWN:-60}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog3_mandelbrot_ispc"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog3/part1_part2_baseline"
SUMMARY="$OUT_DIR/summary.csv"
RAW_LOG="$OUT_DIR/raw.log"

mkdir -p "$OUT_DIR"

cd "$PROG_DIR"
make clean >/dev/null
make >/dev/null

printf "view,mode,run,serial_ms,ispc_ms,task_ms,ispc_speedup,task_speedup,task_over_ispc\n" > "$SUMMARY"

run_case() {
  local view="$1"
  local mode="$2"
  local args=()
  local label="view${view}_${mode}"

  if [[ "$view" != "1" ]]; then
    args+=(--view "$view")
  fi
  if [[ "$mode" == "tasks" ]]; then
    args+=(--tasks)
  fi

  {
    echo
    echo "=== ${label}: cooldown ${COOLDOWN}s + ${RUNS} measured invocations ==="
  } | tee -a "$RAW_LOG"

  sleep "$COOLDOWN"

  for run in $(seq 1 "$RUNS"); do
    {
      echo "--- ${label} invocation ${run} ---"
    } | tee -a "$RAW_LOG"

    out=$(./mandelbrot_ispc "${args[@]}")
    echo "$out" | tee -a "$RAW_LOG" >/dev/null

    serial_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '1p')
    ispc_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '2p')
    task_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '3p')
    ispc_speedup=$(echo "$out" | awk -F'[()]' '/speedup from ISPC/ {gsub(/x speedup from ISPC/, "", $2); print $2; exit}')
    task_speedup=$(echo "$out" | awk -F'[()]' '/speedup from task ISPC/ {gsub(/x speedup from task ISPC/, "", $2); print $2}')

    if [[ -z "$task_ms" ]]; then
      task_ms=""
      task_speedup=""
      task_over_ispc=""
    else
      task_over_ispc=$(awk -v ispc="$ispc_ms" -v task="$task_ms" 'BEGIN { printf "%.3f", ispc / task }')
    fi

    printf "%s,%s,%s,%s,%s,%s,%s,%s,%s\n" \
      "$view" "$mode" "$run" "$serial_ms" "$ispc_ms" "$task_ms" \
      "$ispc_speedup" "$task_speedup" "$task_over_ispc" >> "$SUMMARY"
  done
}

: > "$RAW_LOG"
run_case 1 no_tasks
run_case 2 no_tasks
run_case 1 tasks
run_case 2 tasks

python3 - "$SUMMARY" "$OUT_DIR/means.csv" <<'PY'
import csv
import sys
from collections import defaultdict

src, dest = sys.argv[1], sys.argv[2]
rows = list(csv.DictReader(open(src, newline="")))
groups = defaultdict(list)
for row in rows:
    groups[(row["view"], row["mode"])].append(row)

fields = [
    "view",
    "mode",
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
    if not vals:
        return ""
    return f"{sum(vals) / len(vals):.3f}"

with open(dest, "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=fields)
    writer.writeheader()
    for view, mode in sorted(groups):
        items = groups[(view, mode)]
        writer.writerow({
            "view": view,
            "mode": mode,
            "runs": len(items),
            "mean_serial_ms": mean(items, "serial_ms"),
            "mean_ispc_ms": mean(items, "ispc_ms"),
            "mean_task_ms": mean(items, "task_ms"),
            "mean_ispc_speedup": mean(items, "ispc_speedup"),
            "mean_task_speedup": mean(items, "task_speedup"),
            "mean_task_over_ispc": mean(items, "task_over_ispc"),
        })
PY

cat "$OUT_DIR/means.csv"
