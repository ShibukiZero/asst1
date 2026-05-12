# Program 5 Q1 Baseline

This experiment benchmarks Program 5 `saxpy` with the starter ISPC no-task and
ISPC task implementations.

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- each measured invocation uses Program 5's built-in minimum of three timings
- input: `N = 20,000,000`, `arrayX[i] = i`, `arrayY[i] = i`, `scale = 2`

Mean results:

| Version | Time (ms) | Bandwidth (GB/s) | GFLOPS |
|---|---:|---:|---:|
| ISPC no tasks | 15.138 | 20.305 | 2.725 |
| ISPC tasks | 12.886 | 23.308 | 3.128 |

The task version is only 1.166x faster than the no-task version. This is
consistent with `saxpy` being limited mainly by memory bandwidth rather than
arithmetic throughput.
