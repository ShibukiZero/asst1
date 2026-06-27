# Program 4 Q1 Baseline

This directory archives the Program 4 starter random-input baseline.

## Protocol

The benchmark was run from WSL with a benchmark script. It rebuilds
`prog4_sqrt` and runs `./sqrt` 5 times. Each measured invocation uses a 60
second cooldown, and each invocation still uses Program 4's built-in minimum
of 3 timing repetitions.

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
