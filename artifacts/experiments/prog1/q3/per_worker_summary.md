# Program 1 Q3 — per-worker timing analysis

## View 1 — per-worker timing summary

| Threads | Fastest worker (id, median ms) | Slowest worker (id, median ms) | Imbalance ratio |
|---|---|---|---|
| 2 | 0, 350.2 ms | 1, 352.4 ms | 1.01× |
| 3 | 0, 127.1 ms | 1, 385.3 ms | 3.03× |
| 4 | 0, 68.1 ms | 2, 280.3 ms | 4.12× |
| 5 | 4, 33.4 ms | 2, 291.9 ms | 8.73× |
| 6 | 0, 22.0 ms | 3, 229.4 ms | 10.43× |
| 7 | 0, 19.4 ms | 3, 231.7 ms | 11.92× |
| 8 | 7, 26.2 ms | 4, 212.3 ms | 8.09× |

## View 2 — per-worker timing summary

| Threads | Fastest worker (id, median ms) | Slowest worker (id, median ms) | Imbalance ratio |
|---|---|---|---|
| 2 | 1, 161.0 ms | 0, 231.4 ms | 1.44× |
| 3 | 2, 108.6 ms | 0, 179.0 ms | 1.65× |
| 4 | 3, 80.5 ms | 0, 148.1 ms | 1.84× |
| 5 | 3, 57.3 ms | 0, 114.1 ms | 1.99× |
| 6 | 5, 47.6 ms | 0, 102.3 ms | 2.15× |
| 7 | 6, 40.8 ms | 0, 93.1 ms | 2.28× |
| 8 | 7, 35.8 ms | 0, 84.3 ms | 2.36× |

