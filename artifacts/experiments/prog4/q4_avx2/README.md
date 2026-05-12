# Program 4 Q4 Manual AVX2

This experiment benchmarks a manually-written AVX2 implementation of the
Program 4 iterative square root kernel against the no-task ISPC implementation.

Implementation summary:

- added `prog4_sqrt/sqrtAVX2.cpp`
- processes 8 `float` values at a time with `__m256`
- uses a vector comparison mask for lanes whose Newton iteration is still active
- preserves inactive lanes with `_mm256_blendv_ps`
- falls back to the scalar loop for any tail elements

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- starter pseudo-random input in approximately `[0.001, 2.999]`
- each measured invocation uses Program 4's built-in minimum of three timings

Mean results:

| version | time ms | speedup vs serial |
|---|---:|---:|
| serial | 761.960 | 1.000x |
| ISPC no tasks | 184.305 | 4.136x |
| manual AVX2 | 139.256 | 5.474x |
| ISPC tasks | 32.242 | 24.146x |

The manual AVX2 runtime is 0.755x the no-task ISPC runtime on this local run,
so it is faster than the no-task ISPC implementation for the starter random
input.
