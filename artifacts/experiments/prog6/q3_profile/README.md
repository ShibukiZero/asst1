# Program 6 Q3 Stage Profiling

This profiling run adds timers around the three major phases inside the
`kMeansThread` main loop:

- `computeAssignments`
- `computeCentroids`
- `computeCost`

The run used the starter-code-generated `data.dat` from the Program 6 Q1/Q2
baseline artifacts.

Result:

| Region | Time (ms) | Share |
|---|---:|---:|
| `computeAssignments` | 9993.753 | 68.9% |
| `computeCentroids` | 1566.253 | 10.8% |
| `computeCost` | 2947.824 | 20.3% |

The program ran 24 K-means iterations and reported total runtime
`14507.854 ms` with profiling instrumentation enabled.

The main hotspot is `computeAssignments`. `computeCost` is also nontrivial, and
both of these regions call `dist`, but the largest single optimization target
under the assignment's "parallelize only one function" rule is
`computeAssignments`.
