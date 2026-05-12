# Program 4 Q2 All-2.999 Input

This experiment benchmarks Program 4 with every input value set to `2.999f`.
The value is inside the starter input range and was checked as a slow constant
for the Newton iteration from `initialGuess = 1.0f`.

Protocol:

- `RUNS=5`
- `COOLDOWN=60`
- each measured invocation uses Program 4's built-in minimum of three timings
- the benchmark script temporarily rewrites the initializer in the WSL checkout,
  rebuilds `prog4_sqrt`, runs `./sqrt`, and restores the source afterward

Mean results:

| input | serial ms | ISPC ms | task ISPC ms | ISPC speedup | task ISPC speedup | task / no-task |
|---|---:|---:|---:|---:|---:|---:|
| all `2.999f` | 1971.284 | 331.099 | 54.287 | 5.958x | 36.346x | 6.104x |

Compared with the Q1 starter random-input baseline, this input performs more
total work but improves no-task SIMD speedup because every lane follows the
same long iteration count.
