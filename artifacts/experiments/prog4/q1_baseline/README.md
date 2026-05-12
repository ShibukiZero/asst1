# Program 4 Q1 Baseline

This directory archives the Program 4 starter random-input baseline.

## Command

The benchmark was run from WSL with:

```bash
bash scripts/bench_prog4_q1.sh
```

The script rebuilds `prog4_sqrt` and runs `./sqrt` 5 times. Each measured
invocation uses a 60 second cooldown, and each invocation still uses Program
4's built-in minimum of 3 timing repetitions.

## Input

The starter input initialization was used:

```cpp
values[i] = .001f + 2.998f * static_cast<float>(rand()) / RAND_MAX;
```

This produces pseudo-random values in approximately `[0.001, 2.999]`.

## Mean Results

| Runs | Serial (ms) | ISPC (ms) | Task ISPC (ms) | ISPC Speedup | Task Speedup | Task / No-Task |
|---:|---:|---:|---:|---:|---:|---:|
| 5 | 791.040 | 193.502 | 30.804 | 4.090 | 25.820 | 6.315 |

## Files

- `summary.csv`: per-invocation parsed timings and speedups.
- `means.csv`: mean values across measured invocations.
- `raw.log`: complete command output for all invocations.
