# Program 1 Q1 — Two-thread spatial decomposition (top/bottom halves)

## Setup

- Hardware: Intel Core i7-8550U (4C / 8T, AVX2), 16 GB DDR4-2400 (WSL2 Ubuntu 24.04)
- Image: 1600 × 1200, maxIterations = 256, view 1
- Compiler: g++ -O3 -std=c++11
- Decomposition: thread 0 → rows `[0, 600)`, thread 1 → rows `[600, 1200)`.
  Implemented as the general contiguous-block formula in
  `prog1_mandelbrot_threads/mandelbrotThread.cpp` with `numThreads = 2`.
- Each reported number is `min` over 5 internal runs (built into `main.cpp`);
  this table records 5 independent invocations of the binary.

## Command

```bash
for i in 1 2 3 4 5; do ./mandelbrot -t 2 -v 1; done
```

## Results

| Run | Serial (ms) | Thread (ms) | Speedup |
|-----|-------------|-------------|---------|
| 1   | 500.5       | 262.7       | 1.91×   |
| 2   | 517.0       | 259.6       | 1.99×   |
| 3   | 558.9       | 306.7       | 1.82×   |
| 4   | 600.5       | 319.4       | 1.88×   |
| 5   | 561.5       | 304.4       | 1.84×   |

- Speedup range: 1.82×–1.99×, mean ≈ 1.89×
- Verification (`verifyResult`) passed every run.

## Notes

- Absolute times drift ~20% across runs (typical thermal throttling on a 15 W
  mobile CPU), but the **ratio** is stable — speedup is the trustworthy metric.
- Sub-2× gap comes from (a) the top and bottom halves of view 1 being only
  approximately equal in iteration cost, (b) thread create/join overhead, and
  (c) shared L3 / memory bandwidth between the two cores.
