#!/usr/bin/env bash
# Benchmark Program 4 with one slow lane per 8-wide SIMD gang.

set -euo pipefail

RUNS=${RUNS:-5}
COOLDOWN=${COOLDOWN:-60}
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROG_DIR="$ROOT_DIR/prog4_sqrt"
OUT_DIR="$ROOT_DIR/artifacts/experiments/prog4/q3_one_slow_per_gang"
SUMMARY="$OUT_DIR/summary.csv"
MEANS="$OUT_DIR/means.csv"
RAW_LOG="$OUT_DIR/raw.log"
MAIN_CPP="$PROG_DIR/main.cpp"
BACKUP="$(mktemp)"

mkdir -p "$OUT_DIR"
cp "$MAIN_CPP" "$BACKUP"
restore_main() {
  cp "$BACKUP" "$MAIN_CPP"
  rm -f "$BACKUP"
}
trap restore_main EXIT

python3 - "$MAIN_CPP" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
old = "values[i] = .001f + 2.998f * static_cast<float>(rand()) / RAND_MAX;"
new = "values[i] = (i % 8 == 0) ? 2.999f : 1.0f;"
if old not in text:
    raise SystemExit("starter random initializer not found")
path.write_text(text.replace(old, new, 1))
PY

cd "$PROG_DIR"
make clean >/dev/null
make >/dev/null

printf "run,serial_ms,ispc_ms,task_ms,ispc_speedup,task_speedup,task_over_ispc\n" > "$SUMMARY"
: > "$RAW_LOG"

{
  echo "=== Program 4 Q3 one slow lane per gang: cooldown ${COOLDOWN}s + ${RUNS} measured invocations ==="
  echo "Input: values[i] = (i % 8 == 0) ? 2.999f : 1.0f"
  echo "Expected effect: each 8-wide gang has one slow lane and seven immediately inactive lanes."
} | tee -a "$RAW_LOG"

for run in $(seq 1 "$RUNS"); do
  echo "--- invocation ${run} (cooldown ${COOLDOWN}s) ---" | tee -a "$RAW_LOG"
  sleep "$COOLDOWN"

  out=$(./sqrt)
  echo "$out" | tee -a "$RAW_LOG" >/dev/null

  serial_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '1p')
  ispc_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '2p')
  task_ms=$(echo "$out" | sed -nE 's/.*\[([0-9.]+)\] ms.*/\1/p' | sed -n '3p')
  ispc_speedup=$(echo "$out" | awk -F'[()]' '/speedup from ISPC/ {gsub(/x speedup from ISPC/, "", $2); print $2; exit}')
  task_speedup=$(echo "$out" | awk -F'[()]' '/speedup from task ISPC/ {gsub(/x speedup from task ISPC/, "", $2); print $2}')
  task_over_ispc=$(awk -v ispc="$ispc_ms" -v task="$task_ms" 'BEGIN { printf "%.3f", ispc / task }')

  printf "%s,%s,%s,%s,%s,%s,%s\n" \
    "$run" "$serial_ms" "$ispc_ms" "$task_ms" \
    "$ispc_speedup" "$task_speedup" "$task_over_ispc" >> "$SUMMARY"
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
    "mean_task_ms",
    "mean_ispc_speedup",
    "mean_task_speedup",
    "mean_task_over_ispc",
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
        "mean_task_ms": mean("task_ms"),
        "mean_ispc_speedup": mean("ispc_speedup"),
        "mean_task_speedup": mean("task_speedup"),
        "mean_task_over_ispc": mean("task_over_ispc"),
    })
PY

cat "$MEANS"
