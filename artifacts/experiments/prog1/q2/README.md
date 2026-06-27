# Program 1 Q2 — Speedup vs Thread Count

## Setup

- Hardware: Intel Core i7-8550U (4C / 8T, AVX2), 16 GB DDR4-2400 (WSL2 Ubuntu 24.04)
- Image: 1600 × 1200, maxIterations = 256
- Compiler: g++ -O3 -std=c++11
- Decomposition: contiguous row blocks; thread `i` owns rows
  `[i * H/N, (i+1) * H/N)`; the last thread absorbs `H % N` remainder.
- Protocol: 5 warmup runs at `-t 8`, then 5 measured runs per thread count.
  Each "speedup" value is itself the min-of-5 reported by the program
  (built-in noise control).

## Files

- `speedup_view1.png`, `speedup_view2.png` — single-view plots
- `speedup_compare.png` — view 1 vs view 2 overlay

## Headline

| Threads | view 1 mean | view 2 mean |
|---|---|---|
| 2 | 1.84× | 1.62× |
| 3 | **1.53× (dip)** | 2.02× |
| 4 | 2.23× | 2.39× |
| 5 | 2.22× | 2.68× |
| 6 | 2.77× | 3.05× |
| 7 | 3.11× | 3.23× |
| 8 | 3.56× | 3.70× |

Speedup is far from linear. View 1 has the famous 3-thread regression — the
middle row block carries most of the iteration cost and bottlenecks the
runtime. View 2 is more chaotic (the heavy region isn't centered), but
contiguous-block decomposition still leaves significant work imbalance.
8-thread speedup tops out near 3.5–3.7× because (a) the slowest block sets
the runtime under any contiguous split, and (b) hyper-threading adds little
on a purely ALU-bound workload like Mandelbrot.
