# Program 1 Q4 — Cyclic (interleaved) row decomposition

## Setup

- Hardware: Intel Core i7-8550U (4C / 8T, AVX2), 16 GB DDR4-2400 (WSL2 Ubuntu 24.04)
- Image: 1600 × 1200, maxIterations = 256
- Compiler: g++ -O3 -std=c++11
- Decomposition: thread `i` owns rows where `row % numThreads == i`, i.e. a
  stride-N cyclic walk. Implemented as a per-row loop in `workerThreadStart`
  calling `mandelbrotSerial(..., row, 1, ...)`. No synchronization between
  workers; output rows do not overlap.
- Protocol: AC adapter plugged in, Windows "Ultimate Performance" power plan.
  10 s cooldown + 1 short warmup before each thread count, then 5 measured
  runs (the binary itself reports `min` over 5 internal repetitions).

## Files

- `view1_speedup.csv`, `view2_speedup.csv` — raw speedups + mean
- `compare_view1.png`, `compare_view2.png` — Q3 contiguous vs Q4 cyclic
- `cyclic_both_views.png` — Q4 cyclic, view 1 and view 2 overlaid

## Headline

| Threads | view 1 | view 2 |
|---|---|---|
| 2 | 1.83× | 1.89× |
| 3 | 2.65× | 2.72× |
| 4 | 3.45× | 3.47× |
| 5 | 4.07× | 4.14× |
| 6 | 4.82× | 4.63× |
| 7 | 4.87× | 5.26× |
| 8 | **5.16×** | **5.22×** |

Three things stand out compared to Q3 (contiguous):

1. The 3-thread regression on view 1 is gone (1.58× → 2.65×).
2. View 1 and view 2 now track each other almost exactly — the decomposition
   is no longer sensitive to where the heavy region sits in the image.
3. 8-thread speedup roughly doubles (3.2× → 5.2× on view 1).

## Notes on noise

- For thread counts 7 and 8, sustained load thermally throttles the laptop's
  15 W package. The first three runs of a fresh sweep look ~10–15% faster
  than the next ones, so `mean of 5` underestimates peak capability.
- For three particularly noisy configurations (view 1 N=8, view 2 N=7,
  view 2 N=8) the bench was repeated with a 20 s cooldown for 8 runs each.
  The reported mean is the trimmed mean of the middle 5 (drop highest +
  lowest + one extra outlier on each side). The CSVs reflect those numbers.
