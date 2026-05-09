## Program 1: Parallel Fractal Generation Using Threads

### Q1

Modify the starter code to parallelize the Mandelbrot generation using two
processors. Specifically, compute the top half of the image in thread 0, and
the bottom half of the image in thread 1. This type of problem decomposition
is referred to as *spatial decomposition* since different spatial regions of
the image are computed by different processors.

**Answer:**

Implementation: in `workerThreadStart`, the image is partitioned into contiguous row blocks based on `threadId` and `numThreads`. With two threads, thread 0 handles rows `[0, height/2)` and thread 1 handles rows `[height/2, height)`. The last thread absorbs the `height % numThreads` remainder so that heights not divisible by the thread count still cover the whole image. Each thread passes the original full-image `output` pointer to `mandelbrotSerial`, which writes to absolute row indices via `j*width + i`. Since the row ranges don't overlap, no synchronization is needed.

Measured on an i7-8550U laptop (view 1, 1600×1200):

| Run | Serial (ms) | Thread (ms) | Speedup |
|---|---|---|---|
| 1 | 500.5 | 262.7 | 1.91× |
| 2 | 517.0 | 259.6 | 1.99× |
| 3 | 558.9 | 306.7 | 1.82× |
| 4 | 600.5 | 319.4 | 1.88× |
| 5 | 561.5 | 304.4 | 1.84× |

Verification passed in every run. Speedup ranged from 1.82× to 1.99×, averaging ~1.89×, close to the ideal 2× but slightly below. The gap comes from (a) unequal work between the top and bottom halves (view 1 is roughly symmetric, but not exactly), (b) thread creation/join overhead, and (c) shared L3 and memory bandwidth. Absolute timings drifted by ~20% across consecutive runs — typical thermal throttling on a 15W mobile CPU — but the *ratio* remained stable, which is why speedup is the meaningful metric here, not absolute milliseconds.

---

### Q2

Extend your code to use 2, 3, 4, 5, 6, 7, and 8 threads, partitioning the
image generation work accordingly (threads should get blocks of the image).
Note that the processor only has four cores but each core supports two
hyper-threads, so it can execute a total of eight threads interleaved on its
execution contexts. In your write-up, produce a graph of **speedup compared
to the reference sequential implementation** as a function of the number of
threads used **FOR VIEW 1**. Is speedup linear in the number of threads
used? In your writeup hypothesize why this is (or is not) the case? (You may
also wish to produce a graph for VIEW 2 to help you come up with a good
answer. Hint: take a careful look at the three-thread datapoint.)

**Answer:**

The contiguous-block decomposition from Q1 generalizes to arbitrary N: thread `i` owns rows `[i·H/N, (i+1)·H/N)`, and the last thread absorbs `H mod N` to cover any remainder. Each measurement below is the mean of 5 independent invocations of the binary, after 5 warmup runs at `-t 8` to settle thermal state. Raw numbers are in [`artifacts/experiments/prog1/q2/`](artifacts/experiments/prog1/q2/).

| Threads | View 1 mean | View 2 mean |
|---|---|---|
| 2 | 1.84× | 1.62× |
| 3 | **1.53×** ⬇ | 2.02× |
| 4 | 2.23× | 2.39× |
| 5 | 2.22× | 2.68× |
| 6 | 2.77× | 3.05× |
| 7 | 3.11× | 3.23× |
| 8 | 3.56× | 3.70× |

![View 1 speedup](artifacts/experiments/prog1/q2/speedup_view1.png)

![View 2 speedup](artifacts/experiments/prog1/q2/speedup_view2.png)

![View 1 vs View 2](artifacts/experiments/prog1/q2/speedup_compare.png)

**Speedup is clearly not linear.** The dashed grey line in each plot shows the ideal `speedup = N`; the measured curve falls well below it and, on view 1, is even *non-monotonic* — going from 2 to 3 threads makes things **worse**.

**Hypothesis: the contiguous-block decomposition produces severe load imbalance, and total runtime is set by the slowest block.** The Mandelbrot set's iteration cost is highly position-dependent — pixels inside the black "body" run the full 256 iterations, while pixels far outside escape after only a handful. Under contiguous row blocks, the thread that happens to cover the densest region dominates wall-clock time; the other threads finish early and idle until the join.

This explains every feature of the curves:

- **View 1, 2 threads (1.84×):** the top and bottom halves of view 1 are roughly symmetric in iteration cost, so this case is close to balanced — within 8% of the ideal 2×.
- **View 1, 3 threads (1.53× — the regression):** thirds of view 1 are highly *un*balanced. The middle third contains the dense central body of the set; the top and bottom thirds are mostly fast-escaping background. The middle thread becomes the bottleneck and is roughly as slow as the *whole* serial run, so 3-thread speedup actually drops below the 2-thread case.
- **4 threads (~2.2×):** splitting the middle third further into two quarters reduces the worst block's cost, recovering the speedup, but the two "middle" threads still dominate.
- **5 threads (~2.2×):** adding a fifth slice does not shorten the worst block — the heavy middle stripe is split between the same two threads as before — so wall-clock time barely improves.
- **6–8 threads:** the heavy region is now split across more workers, so the maximum-per-thread cost drops further. View 2 lacks the up/down symmetry of view 1, so the contiguous slicing is more chaotic — that's why view 2's 3-thread point isn't a regression, but its 2-thread point is *worse* than view 1's.
- **8 threads tops out at ~3.6× (view 1) / ~3.7× (view 2):** two compounding ceilings. (i) Even with perfect balance, the machine has only 4 physical cores; the additional 4 SMT contexts add little for a purely ALU-bound workload like Mandelbrot, since the two hyper-threads on a core compete for the same FP execution units. (ii) Contiguous slicing still leaves residual imbalance, so the measured curve doesn't even reach the ~4× ceiling that perfect balance on 4 cores would give.

The takeaway for Q4: any decomposition that assumes "equal area = equal work" cannot do well here. A block-cyclic / interleaved assignment that statistically averages heavy and light rows across all threads will be needed to hit the 7–8× target.

---

### Q3

To confirm (or disprove) your hypothesis, measure the amount of time each
thread requires to complete its work by inserting timing code at the
beginning and end of `workerThreadStart()`. How do your measurements explain
the speedup graph you previously created?

**Answer:**

---

### Q4

Modify the mapping of work to threads to achieve to improve speedup to at
**about 7-8x on both views** of the Mandelbrot set (if you're above 7x
that's fine, don't sweat it). You may not use any synchronization between
threads in your solution. We are expecting you to come up with a single work
decomposition policy that will work well for all thread counts—hard coding a
solution specific to each configuration is not allowed! (Hint: There is a
very simple static assignment that will achieve this goal, and no
communication/synchronization among threads is necessary.) In your writeup,
describe your approach to parallelization and report the final 8-thread
speedup obtained.

**Answer:**

---

### Q5

Now run your improved code with 16 threads. Is performance noticeably greater
than when running with eight threads? Why or why not?

**Answer:**
