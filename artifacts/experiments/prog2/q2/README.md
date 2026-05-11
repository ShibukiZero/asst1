# Program 2 Q2 Vector Width Sweep

This directory archives the `./myexp -s 10000` vector-width sweep used for
Program 2 Q2.

## Command

The sweep was run from WSL with:

```bash
bash scripts/bench_prog2_widths.sh
```

The script temporarily edits `prog2_vecintrin/CS149intrin.h`, rebuilds
`prog2_vecintrin`, runs `./myexp -s 10000`, parses the vector unit statistics,
and restores the original header.

## Results

| Vector Width | Total Vector Instructions | Vector Utilization | Required Passed |
|---:|---:|---:|---|
| 2 | 177724 | 87.2% | yes |
| 4 | 102072 | 81.8% | yes |
| 8 | 55374 | 79.0% | yes |
| 16 | 28839 | 77.7% | yes |

Raw logs are saved as `vector_width_2.log`, `vector_width_4.log`,
`vector_width_8.log`, and `vector_width_16.log`. The parsed summary is in
`vector_width_sweep.csv`.
