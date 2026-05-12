# Program 5 Q3 Streaming Stores

This experiment benchmarks a manual AVX2 `saxpy` implementation that uses
non-temporal streaming stores for the `result` array.

Implementation summary:

- added `prog5_saxpy/saxpyStreaming.cpp`
- uses `_mm256_load_ps` for aligned loads from `X` and `Y`
- uses `_mm256_stream_ps` for aligned non-temporal stores to `result`
- uses `_mm_sfence()` after streaming stores before verification reads
- changes Program 5 allocation to 32-byte aligned `posix_memalign`

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- input: `N = 20,000,000`, `arrayX[i] = i`, `arrayY[i] = i`, `scale = 2`
- each measured invocation uses Program 5's built-in minimum of three timings

Mean results:

| Version | Time (ms) | Bandwidth (GB/s) | GFLOPS |
|---|---:|---:|---:|
| ISPC no tasks | 14.388 | 21.244 | 2.851 |
| ISPC tasks | 13.256 | 22.500 | 3.020 |
| AVX2 streaming stores | 10.754 | 28.239 | 3.790 |

The streaming-store implementation is 1.342x faster than the no-task ISPC
implementation in this run. It is also faster than the 64-task ISPC version on
this local machine.
