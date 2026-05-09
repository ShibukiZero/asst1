## Program 1: Parallel Fractal Generation Using Threads

### Q1

Modify the starter code to parallelize the Mandelbrot generation using two
processors. Specifically, compute the top half of the image in thread 0, and
the bottom half of the image in thread 1. This type of problem decomposition
is referred to as *spatial decomposition* since different spatial regions of
the image are computed by different processors.

**Answer:**

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
