# Program 1 Q5 — 16 threads with cyclic decomposition

## Setup

- Same as Q4: i7-8550U, AC plugged in, Ultimate Performance plan,
  20 s cooldown + 1 warmup, 8 measured invocations per view.
- Cyclic decomposition (the Q4 worker, unchanged) just invoked with `-t 16`.

## Results (8 invocations each view)

**view 1:** 4.90, 4.91, 5.03, 5.11, 5.28, 5.65, 5.67, 5.73
- min 4.90, max 5.73
- trimmed mean of middle 5 = **5.20×**

**view 2:** 4.06, 4.51, 5.06, 5.19, 5.46, 5.55, 5.55, 5.61
- min 4.06, max 5.61
- trimmed mean of middle 5 = **5.24×**

## Comparison to Q4 8-thread

| | Q4 (-t 8) | Q5 (-t 16) | Δ |
|---|---|---|---|
| view 1 | 5.16× | 5.20× | +0.04× |
| view 2 | 5.22× | 5.24× | +0.02× |

Within run-to-run noise; effectively no change.
