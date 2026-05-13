# Program 6 Q4 Parallel Assignments

This experiment parallelizes `computeAssignments` across the data-point
dimension `m` using 8 `std::thread` workers.

Implementation summary:

- `computeAssignments` now treats `WorkerArgs::start` and `WorkerArgs::end` as
  a range of data-point indices.
- Each worker owns a contiguous `m` range.
- For each assigned point, the worker computes distances to all `K` centroids
  and writes only that point's `clusterAssignments[m]`.
- No lock is needed because output indices do not overlap across workers.
- `kMeansThread` hard-codes 8 threads for this assignment environment.

Result on the starter-code-generated `data.dat`:

| Version | Total time (ms) | Speedup |
|---|---:|---:|
| Starter baseline | 19673.032 | 1.000x |
| Parallel `computeAssignments` | 7878.379 | 2.497x |

The implementation exceeds the assignment target of 2.1x. The improvement is
consistent with the Q3 profile, where `computeAssignments` accounted for 68.9%
of the profiled runtime.
