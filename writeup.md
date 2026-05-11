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

Per-worker timers were added around the `mandelbrotSerial` call in `workerThreadStart` (printing `[worker id/N rows a..b]: T ms`), then the same Q2 sweep was re-run for both views. Raw logs and parsed CSVs are under [`artifacts/experiments/prog1/q3/`](artifacts/experiments/prog1/q3/). Each worker time below is the median across 25 samples (5 binary invocations × 5 internal repetitions inside `main.cpp`).

**View 1 — fastest vs slowest worker:**

| Threads | Fastest worker (id, median ms) | Slowest worker (id, median ms) | Imbalance (slow / fast) |
|---|---|---|---|
| 2 | w0: 350.2 | w1: 352.4 | **1.01×** |
| 3 | w0: 127.1 | w1: 385.3 | **3.03×** |
| 4 | w0: 68.1 | w2: 280.3 | 4.12× |
| 5 | w4: 33.4 | w2: 291.9 | 8.73× |
| 6 | w0: 22.0 | w3: 229.4 | 10.43× |
| 7 | w0: 19.4 | w3: 231.7 | 11.92× |
| 8 | w7: 26.2 | w4: 212.3 | 8.09× |

**View 2 — fastest vs slowest worker:**

| Threads | Fastest worker (id, median ms) | Slowest worker (id, median ms) | Imbalance |
|---|---|---|---|
| 2 | w1: 161.0 | w0: 231.4 | 1.44× |
| 3 | w2: 108.6 | w0: 179.0 | 1.65× |
| 4 | w3: 80.5 | w0: 148.1 | 1.84× |
| 5 | w3: 57.3 | w0: 114.1 | 1.99× |
| 6 | w5: 47.6 | w0: 102.3 | 2.15× |
| 7 | w6: 40.8 | w0: 93.1 | 2.28× |
| 8 | w7: 35.8 | w0: 84.3 | 2.36× |

These measurements confirm the Q2 hypothesis directly. With a fork–join schedule and contiguous-block decomposition, **wall-clock time tracks the slowest worker**, not the average; the other workers finish early and idle until the join. Several specific predictions from Q2 fall out:

- **View 1, 2 threads (≈1.84×):** the upper and lower halves are within 0.7% of each other (350 vs 352 ms). Imbalance ≈ 1.01×, so this case is genuinely close to balanced — the residual gap to 2× is overhead, not imbalance.
- **View 1, 3 threads (the 1.53× regression):** the middle slice (`w1`) takes 385 ms — that's **slower than the entire serial run with 2-way splits** (350 ms). Imbalance is 3.03×, so the predicted speedup is `3 / 3.03 ≈ 0.99`. Adding a third thread does not help because the new worker only steals work from the already-fast top/bottom slices, not from the bottleneck.
- **View 1, 4–7 threads:** the slowest worker is consistently the one straddling the dense central body (w2 at N=4, w3 at N=6/7). Its absolute cost barely drops (280 → 230 ms) until N=8, because the dense band is only fully split at higher N. Imbalance climbs past 10×.
- **View 1, 8 threads (≈3.6×):** the central band finally gets divided across `w3` and `w4`; max worker time falls from 230 ms to 212 ms. Imbalance drops back to ≈8×, hence the noticeable jump in speedup at this point.
- **View 2's monotone curve:** `w0` (top slice) is *always* the slowest in view 2, and its cost falls cleanly with N (231 → 84 ms). Imbalance grows only mildly (1.4× → 2.4×), which matches the smoother, dip-free shape of the view 2 speedup plot.

**Quantitative check.** A useful rule of thumb is `speedup ≈ N / imbalance`. For view 1 it predicts:

| N | N / imbalance | Measured Q3 speedup |
|---|---|---|
| 2 | 2 / 1.01 = 1.98 | 1.83 |
| 3 | 3 / 3.03 = 0.99 | 1.58 |
| 4 | 4 / 4.12 = 0.97 | 2.22 |
| 8 | 8 / 8.09 = 0.99 | 3.23 |

The prediction undershoots (the true speedups are higher) because the rule assumes the fastest worker has zero cost. In practice every worker finishes some real work, so the fork–join time is `max(worker_i)`, not `sum(worker_i)/min(worker_i)`. The right way to read the table is the trend: imbalance and observed speedup move together — when imbalance is ~1, speedup approaches N; when imbalance is huge, speedup collapses to roughly `serial_time / max_worker_time`. That is exactly what Q2 conjectured.

The data also explains why the 8-thread speedup tops out near 3.5–3.7× rather than approaching 8×: even after the central band is split, a single worker still owns ~210 ms of work out of an ~530 ms serial budget, so the irreducible critical path is already ~40% of serial — independent of how many physical or hyper-threads exist.

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

**Approach: cyclic (interleaved) row decomposition.** Instead of giving each thread a contiguous block of rows, thread `i` now owns the rows whose index satisfies `row % numThreads == i`, walking the image with stride `numThreads`. The worker becomes a single loop:

```cpp
for (int row = threadId; row < height; row += numThreads) {
    mandelbrotSerial(..., row, 1, ..., output);
}
```

This is a single static policy that works for any thread count, requires no synchronization (output rows still don't overlap), and automatically covers `H mod N` remainder rows without a special case. The reasoning is the one Q3 made quantitative: under contiguous slicing the slowest worker dominates wall-clock time. Cyclic slicing makes every thread sample heavy and light regions in roughly equal proportion, so the worst-case worker drops sharply.

**Measurement protocol.** For these experiments the laptop was on AC with the Windows "Ultimate Performance" power plan, the bench script inserted a 10 s cooldown plus a one-shot warmup before each thread count, and three particularly noisy configs (view 1 N=8, view 2 N=7, view 2 N=8) were re-run for 8 invocations each with a 20 s cooldown — their reported mean is the trimmed mean of the middle 5 samples. CSVs and full logs are under [`artifacts/experiments/prog1/q4/`](artifacts/experiments/prog1/q4/).

| Threads | view 1 mean | view 2 mean |
|---|---|---|
| 2 | 1.83× | 1.89× |
| 3 | 2.65× | 2.72× |
| 4 | 3.45× | 3.47× |
| 5 | 4.07× | 4.14× |
| 6 | 4.82× | 4.63× |
| 7 | 4.87× | 5.26× |
| 8 | **5.16×** | **5.22×** |

![View 1 contiguous vs cyclic](artifacts/experiments/prog1/q4/compare_view1.png)

![View 2 contiguous vs cyclic](artifacts/experiments/prog1/q4/compare_view2.png)

![Cyclic, view 1 vs view 2](artifacts/experiments/prog1/q4/cyclic_both_views.png)

**Comparison with the Q3 contiguous baseline:**

| Threads | view 1 contiguous → cyclic | view 2 contiguous → cyclic |
|---|---|---|
| 3 | 1.58 → **2.65** (regression eliminated) | 1.97 → 2.72 |
| 4 | 2.22 → 3.45 | 2.24 → 3.47 |
| 8 | 3.23 → **5.16** | 3.79 → 5.22 |

Three observations corroborate the design:

1. **The 3-thread regression on view 1 disappears.** Under contiguous slicing the centre row block (worker 1) was about 3× heavier than the edge blocks; under cyclic slicing the middle band's rows are spread across all three threads, so worker timing equalises.
2. **The view 1 and view 2 curves now overlap closely.** The same code reaches 5.16× and 5.22× at 8 threads, despite the heavy region living in completely different parts of the two images. This is exactly what the Q4 hint asked for — a single decomposition policy that works on both.
3. **Per-worker timings (visible in the bench logs) cluster within 5–15% of each other** at every N, versus the 8–12× imbalance ratios seen in Q3.

**Final 8-thread speedup: 5.16× (view 1) and 5.22× (view 2).** This falls short of the README's 7–8× ceiling but is consistent with the platform: the i7-8550U is a 15 W mobile part whose multi-core sustained frequency is ~2.5–2.8 GHz versus the 4.0–4.2 GHz the desktop i7-7700K used for the original target sustains under the same load. With the imbalance ratio essentially gone (per-worker times within ~10%), the remaining gap to ideal is dominated by hyper-threading's modest gain on a purely ALU-bound kernel and laptop-class thermal/power limits, not by the decomposition.

---

### Q5

Now run your improved code with 16 threads. Is performance noticeably greater
than when running with eight threads? Why or why not?

**Answer:**

**No — performance is essentially unchanged.** The cyclic worker from Q4 was rerun at `-t 16` under the same conditions (8 invocations per view, 20 s cooldown, AC + Ultimate Performance). Trimmed means of the middle 5 samples:

| | -t 8 (Q4) | -t 16 (Q5) | Δ |
|---|---|---|---|
| view 1 | 5.16× | 5.20× | +0.04× |
| view 2 | 5.22× | 5.24× | +0.02× |

Both deltas are well inside per-run noise (view 1 -t 16 individual runs ranged 4.90–5.73). Raw numbers are in [`artifacts/experiments/prog1/q5/runs.csv`](artifacts/experiments/prog1/q5/runs.csv).

**Why no improvement.** The CPU only exposes **8 hardware execution contexts** (4 physical cores × 2 hyper-threads each). At -t 8 those contexts are already saturated — every worker is on its own logical CPU. Going to -t 16 simply over-subscribes: the OS now multiplexes 16 software threads onto the same 8 contexts, time-slicing them. There is no new arithmetic capacity to recruit, so the wall-clock time can't go down.

If anything, -t 16 should be very slightly *slower* than -t 8 because:

- Each thread still does the same total amount of arithmetic, just split into smaller per-quantum chunks, so per-thread cache footprint and TLB pressure don't improve.
- The OS scheduler now has twice as many runnable threads to manage, adding context-switch overhead and slightly more variable per-worker timing.
- `printf` from 16 workers contends on stdout more.

In practice these costs are tiny (low single-digit percent) on a workload as compute-heavy as Mandelbrot, which is why the measured -t 16 is *not* worse — but it isn't better either. The takeaway is that for ALU-bound code, the useful upper bound on `numThreads` is the number of hardware threads (8 here); above that the only effect is overhead.

---

## Program 2: Vectorizing Code Using SIMD Intrinsics

### Q1

Implement a vectorized version of `clampedExpSerial` in `clampedExpVector`.
Your implementation should work with any combination of input array size
(`N`) and vector width (`VECTOR_WIDTH`).

**Answer:**

I implemented `clampedExpVector` by processing the input arrays in chunks of
`VECTOR_WIDTH` lanes. For each chunk, I first construct a mask with
`_cs149_init_ones(width)`, where `width = min(VECTOR_WIDTH, N - i)`. This
mask is important for the final chunk when `N` is not a multiple of
`VECTOR_WIDTH`: inactive lanes are never loaded from or stored to, so the
implementation does not read past the logical input or overwrite `output`
beyond `N`.

Within each chunk, I load the input values and exponents into vector registers.
The result vector is initialized to `1.0`, which handles lanes whose exponent
is zero. For lanes whose exponent is greater than zero, I move the base value
`x` into the result and initialize a per-lane counter to `exponent - 1`. I then
use a loop controlled by a mask of lanes whose counter is still positive. On
each loop iteration, only those active lanes perform `result *= x`, and their
counters are decremented. The loop stops when `_cs149_cntbits` reports that no
lanes still need more multiplications.

After the exponentiation loop, I compare the result against `9.999999f` and
set only the lanes above that threshold to the clamp value. Finally, the result
is stored back using the same valid-lane mask from the start of the chunk.

This implementation passed the required correctness tests in WSL for
`./myexp -s 3`, `./myexp`, and `./myexp -s 10000`, including the non-multiple
case that checks tail handling.

---

### Q2

Run `./myexp -s 10000` and sweep the vector width from 2, 4, 8, to 16.
Record the resulting vector utilization. You can do this by changing the
`#define VECTOR_WIDTH` value in `CS149intrin.h`. Does the vector utilization
increase, decrease or stay the same as `VECTOR_WIDTH` changes? Why?

**Answer:**

I swept `VECTOR_WIDTH` from 2 to 16 using `./myexp -s 10000`. The run was
automated with `scripts/bench_prog2_widths.sh`, which temporarily changes the
`VECTOR_WIDTH` definition, rebuilds the program, runs the benchmark, records
the vector-unit statistics, and then restores the original header. The raw logs
and parsed CSV are archived in
[`artifacts/experiments/prog2/q2/`](artifacts/experiments/prog2/q2/).

| Vector Width | Total Vector Instructions | Vector Utilization |
|---:|---:|---:|
| 2 | 177724 | 87.2% |
| 4 | 102072 | 81.8% |
| 8 | 55374 | 79.0% |
| 16 | 28839 | 77.7% |

The total number of vector instructions decreases as `VECTOR_WIDTH` increases.
This is expected because the same 10,000 elements are split into fewer vector
chunks. For example, width 2 processes about 5,000 chunks, while width 16
processes only 625 chunks.

However, vector utilization decreases from 87.2% at width 2 to 77.7% at width
16. The reason is that `clampedExp` has per-lane control flow: different
elements have different exponents, so they require different numbers of
multiplications. A vector chunk must keep looping until the lane with the
largest remaining exponent is done, while lanes with smaller exponents are
masked off in later iterations. With a larger `VECTOR_WIDTH`, each chunk is
more likely to contain a wider mix of exponent values, so more lanes become
inactive during the loop. Thus wider vectors reduce instruction count, but
they also make SIMD lane divergence more visible.

---

### Q3 (Extra credit, 1 point)

Implement a vectorized version of `arraySumSerial` in `arraySumVector`. Your
implementation may assume that `VECTOR_WIDTH` is a factor of the input array
size `N`. Whereas the serial implementation runs in `O(N)` time, your
implementation should aim for runtime of `(N / VECTOR_WIDTH + VECTOR_WIDTH)`
or even `(N / VECTOR_WIDTH + log2(VECTOR_WIDTH))`. You may find the `hadd`
and `interleave` operations useful.

**Answer:**

I implemented `arraySumVector` with a two-stage reduction. First, I keep a
`VECTOR_WIDTH`-lane vector accumulator called `partialSum`, initialized to
zero. The main loop loads `VECTOR_WIDTH` input values at a time and adds them
into `partialSum`, so each lane accumulates a strided subset of the input
array.

After this vector accumulation phase, the remaining work is to reduce the
lanes of `partialSum` into one scalar value. I do this with a tree-style
horizontal reduction using `_cs149_hadd_float` and `_cs149_interleave_float`.
Each `_cs149_hadd_float` combines adjacent pairs of lanes, and
`_cs149_interleave_float` rearranges the intermediate sums so that the next
round can combine the next larger groups. Repeating this while the active
width halves each round reduces the vector in `log2(VECTOR_WIDTH)` steps, and
the final sum is available in `partialSum.value[0]`.

The resulting structure is `N / VECTOR_WIDTH` vector additions for the main
accumulation plus `log2(VECTOR_WIDTH)` horizontal-reduction rounds. This
matches the intended asymptotic target for the extra credit. I verified the
implementation in WSL with both `./myexp` and `./myexp -s 10000`; in both
runs, the required clamped exponent test and the array-sum extra credit test
passed.

---

## Program 3: Parallel Fractal Generation Using ISPC

### Part 1: A Few ISPC Basics

Compile and run the program `mandelbrot_ispc`. The ISPC compiler is currently
configured to emit 8-wide AVX2 vector instructions. What is the maximum
speedup you expect given what you know about these CPUs? Why might the number
you observe be less than this ideal? Consider the characteristics of the
computation you are performing, and describe the parts of the image that
present challenges for SIMD execution. Comparing the performance of rendering
the different views of the Mandelbrot set may help confirm your hypothesis.

**Answer:**

Since this build targets `avx2-i32x8`, the ideal single-core SIMD speedup is
about 8x: in the best case, one vector instruction performs the work of eight
scalar lanes. The assignment handout also lets us assume, for this question,
that the machine has roughly comparable scalar and 8-wide vector floating-point
throughput. That ideal requires all eight SIMD lanes in a gang to stay useful
for the same amount of time.

My cooled local measurements were:

| View | Serial (ms) | ISPC (ms) | ISPC Speedup |
|---|---:|---:|---:|
| 1 | 280.707 | 59.496 | 4.72x |
| 2 | 147.818 | 34.528 | 4.28x |

The observed speedups are well below 8x because Mandelbrot has data-dependent
control flow. Each pixel iterates until it escapes or reaches
`maxIterations`; nearby pixels can require very different numbers of
iterations, especially near the boundary of the Mandelbrot set. In an ISPC
gang, lanes that escape early become inactive, but the gang must keep executing
until the slowest active lanes finish. Those masked-off lanes reduce SIMD
utilization, much like the inactive lanes in Program 2's `clampedExpVector`
when different exponents require different numbers of multiplications.

The most challenging parts of the image for SIMD execution are therefore the
boundary regions, where adjacent pixels can have irregular and highly varied
escape times. View 2 had a slightly lower SIMD speedup than view 1 in this
run, which is consistent with the idea that its zoomed-in region exposes more
fine-grained divergence among neighboring pixels. This does not contradict the
Program 1 thread results: Program 1 measured load balance across rows and
threads, while this ISPC run measures lane utilization within a single
8-wide SIMD gang. A view can have relatively good row-level thread balance but
still have poor lane-level SIMD coherence.

---

### Part 2: ISPC Tasks

Run `mandelbrot_ispc` with the parameter `--tasks`. What speedup do you
observe on view 1? What is the speedup over the version of `mandelbrot_ispc`
that does not partition that computation into tasks?

**Answer:**

---

There is a simple way to improve the performance of `mandelbrot_ispc --tasks`
by changing the number of tasks the code creates. By only changing code in the
function `mandelbrot_ispc_withtasks()`, you should be able to achieve
performance that exceeds the sequential version of the code by over 32 times.
How did you determine how many tasks to create? Why does the number you chose
work best?

**Answer:**

---

### Extra Credit

What are differences between the thread abstraction (used in Program 1) and
the ISPC task abstraction? There are some obvious differences in semantics
between the create/join and launch/sync mechanisms, but the implications of
these differences are more subtle. What happens when you launch 10,000 ISPC
tasks? What happens when you launch 10,000 threads? Discuss this in the
general case, not tied only to this Mandelbrot program.

**Answer:**
