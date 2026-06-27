# Program 3 Part 1 and Starter Part 2 Baseline

This directory archives repeated baseline measurements for Program 3 before
changing the number of ISPC tasks.

## Protocol

The benchmark was run from WSL with a benchmark script. It rebuilds
`prog3_mandelbrot_ispc`, then runs view 1 and view 2 in both no-task and
starter `--tasks` modes. Each configuration uses a 60 second cooldown and 5
measured invocations. Each invocation still uses the program's built-in
minimum of 3 timing repetitions.

## Mean Results

| View | Mode | Runs | Serial (ms) | ISPC (ms) | Task ISPC (ms) | ISPC Speedup | Task Speedup | Task / No-Task |
|---:|---|---:|---:|---:|---:|---:|---:|---:|
| 1 | no tasks | 5 | 240.755 | 49.633 | | 4.852 | | |
| 1 | tasks | 5 | 241.241 | 49.268 | 25.599 | 4.898 | 9.426 | 1.925 |
| 2 | no tasks | 5 | 147.309 | 35.115 | | 4.198 | | |
| 2 | tasks | 5 | 139.850 | 33.799 | 20.264 | 4.136 | 6.898 | 1.668 |
