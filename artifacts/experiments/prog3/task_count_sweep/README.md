# Program 3 Task Count Sweep

This directory archives a sweep over the number of ISPC tasks created by
`mandelbrot_ispc_withtasks()` for Program 3 Part 2.

## Protocol

The sweep was run from WSL with a benchmark script. It temporarily edits
`prog3_mandelbrot_ispc/mandelbrot.ispc`, rebuilds Program 3, runs
`./mandelbrot_ispc --tasks`, and restores the original ISPC file on exit. Each
task count uses 5 measured invocations and a 10 second cooldown. Each
invocation still uses Program 3's built-in minimum of 3 timing repetitions.

Only task counts that evenly divide the 800 image rows were swept, so the
temporary `rowsPerTask = height / task_count` transformation preserves full
image coverage without modifying `mandelbrot_ispc_task()`.

## Mean Results

| Tasks | Task ISPC (ms) | Speedup vs Serial | Task / No-Task |
|---:|---:|---:|---:|
| 2 | 46.946 | 8.232 | 1.905 |
| 4 | 30.371 | 10.674 | 2.180 |
| 8 | 13.556 | 18.356 | 3.863 |
| 16 | 8.871 | 26.780 | 5.622 |
| 25 | 8.173 | 30.554 | 6.473 |
| 40 | 8.107 | 28.674 | 6.035 |
| 50 | 8.410 | 30.032 | 6.236 |
| 80 | 8.998 | 28.590 | 6.118 |
| 100 | 8.346 | 29.888 | 6.165 |
| 160 | 8.535 | 28.144 | 5.927 |

Task runtime improves sharply through 16 tasks, then plateaus around 8-9 ms.
The lowest mean task time in this sweep was 8.107 ms at 40 tasks; the highest
speedup ratio was 30.554x at 25 tasks, partly because the serial baseline
varied across runs.
