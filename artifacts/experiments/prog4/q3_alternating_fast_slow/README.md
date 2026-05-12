# Program 4 Q3 Alternating Fast/Slow Input

This experiment benchmarks Program 4 with alternating fast and slow inputs:

```cpp
values[i] = (i % 2 == 0) ? 1.0f : 2.999f;
```

`1.0f` is the fastest checked value because the initial guess is already exact
and the Newton loop runs 0 iterations. `2.999f` is a slow in-range value near
the upper end of the starter random input range.

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- each measured invocation uses Program 4's built-in minimum of three timings
- the benchmark script temporarily rewrites the initializer in the WSL checkout,
  rebuilds `prog4_sqrt`, runs `./sqrt`, and restores the source afterward

Mean results:

| input | serial ms | ISPC ms | task ISPC ms | ISPC speedup | task ISPC speedup | task / no-task |
|---|---:|---:|---:|---:|---:|---:|
| alternating `1.0f` / `2.999f` | 973.001 | 325.768 | 52.565 | 2.986x | 18.560x | 6.223x |

Compared with the all-`2.999f` Q2 input, the serial time is roughly halved
because half the elements exit immediately. The no-task ISPC time remains close
to the all-slow case because every 8-wide gang still contains slow lanes, so
the fast lanes are masked off while waiting for the slow lanes to finish.
