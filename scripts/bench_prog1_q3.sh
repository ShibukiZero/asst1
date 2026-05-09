#!/usr/bin/env bash
# Re-run prog1 across thread counts with per-worker timing prints enabled.
# Captures both speedup-vs-threads and per-worker durations.
# Usage: ./bench_prog1_q3.sh [view]   (default view=1)

set -e
VIEW=${1:-1}
BIN=./mandelbrot
RUNS=5
WARMUPS=5
OUT_DIR="$(dirname "$0")/../artifacts/experiments/prog1/q3"
mkdir -p "$OUT_DIR"

cd "$(dirname "$0")/../prog1_mandelbrot_threads"

LOG="$OUT_DIR/view${VIEW}_raw.log"
SPEEDUP_CSV="$OUT_DIR/view${VIEW}_speedup.csv"
echo "threads,run1,run2,run3,run4,run5,mean" > "$SPEEDUP_CSV"

{
echo "=== Warmup: $WARMUPS runs at -t 8 -v $VIEW ==="
for i in $(seq 1 $WARMUPS); do
    $BIN -t 8 -v $VIEW > /dev/null
done

echo
echo "=== Measurements: $RUNS runs per thread count, view $VIEW ==="
for T in 2 3 4 5 6 7 8; do
    echo
    echo "------- threads = $T -------"
    speedups=()
    for i in $(seq 1 $RUNS); do
        echo "--- invocation $i ---"
        out=$($BIN -t $T -v $VIEW)
        echo "$out"
        s=$(echo "$out" | grep -oE '[0-9]+\.[0-9]+x speedup' | grep -oE '[0-9]+\.[0-9]+')
        speedups+=("$s")
    done
    sum=$(echo "${speedups[@]}" | tr ' ' '+' | bc -l)
    mean=$(echo "scale=3; $sum / $RUNS" | bc -l)
    printf "%d,%s,%s\n" "$T" "$(IFS=,; echo "${speedups[*]}")" "$mean" >> "$SPEEDUP_CSV"
done
} | tee "$LOG"

echo
echo "Wrote: $LOG"
echo "Wrote: $SPEEDUP_CSV"
