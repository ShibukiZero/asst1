#!/usr/bin/env bash
# Benchmark prog1 across thread counts.
# Usage: ./bench_prog1.sh [view]   (default view=1)

set -e
VIEW=${1:-1}
BIN=./mandelbrot
RUNS=5
WARMUPS=5

cd "$(dirname "$0")/../prog1_mandelbrot_threads"

echo "=== Warmup: $WARMUPS runs at -t 8 -v $VIEW ==="
for i in $(seq 1 $WARMUPS); do
    $BIN -t 8 -v $VIEW > /dev/null
done

echo
echo "=== Measurements: $RUNS runs per thread count, view $VIEW ==="
printf "%-8s | %-40s | %-8s\n" "threads" "speedups" "mean"
echo "---------|------------------------------------------|--------"

for T in 2 3 4 5 6 7 8; do
    sums="0"
    line=""
    for i in $(seq 1 $RUNS); do
        s=$($BIN -t $T -v $VIEW | grep -oE '[0-9]+\.[0-9]+x speedup' | grep -oE '[0-9]+\.[0-9]+')
        line="$line $s"
        sums="$sums + $s"
    done
    mean=$(echo "scale=3; ($sums) / $RUNS" | bc -l)
    printf "%-8s |%-41s | %sx\n" "$T" "$line" "$mean"
done
