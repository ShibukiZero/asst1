# Program 6 Q4 Post-Optimization Profiling

This profiling run repeats the stage timing after parallelizing
`computeAssignments` across 8 threads.

The run used the same starter-code-generated `data.dat` as the Q1/Q2 baseline
and Q4 optimization run.

Result:

| Region | Before optimization | After optimization |
|---|---:|---:|
| `computeAssignments` | 9993.753 ms (68.9%) | 1803.601 ms (27.0%) |
| `computeCentroids` | 1566.253 ms (10.8%) | 1670.920 ms (25.0%) |
| `computeCost` | 2947.824 ms (20.3%) | 3206.972 ms (48.0%) |

The program again ran 24 K-means iterations. After the assignment phase is
parallelized, `computeCost` becomes the largest remaining stage. This is the
expected bottleneck shift after speeding up the original dominant phase.
