# Program 4 Q3 One Slow Lane Per Gang

This experiment benchmarks Program 4 with one slow input in each 8-wide AVX2
gang:

```cpp
values[i] = (i % 8 == 0) ? 2.999f : 1.0f;
```

`1.0f` is the fastest checked value because the initial guess is already exact
and the Newton loop runs 0 iterations. `2.999f` is a slow in-range value near
the upper end of the starter random input range. The pattern leaves one slow
lane in each gang, so the SIMD loop still waits for a slow lane while seven
lanes become inactive immediately.

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- each measured invocation uses Program 4's built-in minimum of three timings
- the benchmark script temporarily rewrites the initializer in the WSL checkout,
  rebuilds `prog4_sqrt`, runs `./sqrt`, and restores the source afterward

Mean results:

| input | serial ms | ISPC ms | task ISPC ms | ISPC speedup | task ISPC speedup | task / no-task |
|---|---:|---:|---:|---:|---:|---:|
| one `2.999f` per 8 values | 275.354 | 323.708 | 51.996 | 0.854x | 5.310x | 6.229x |

Compared with the alternating 4-fast/4-slow input, the no-task ISPC runtime is
almost unchanged, but the serial runtime is much faster. This makes the
reported no-task ISPC speedup fall below 1x.
