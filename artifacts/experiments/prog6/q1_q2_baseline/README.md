# Program 6 Q1/Q2 Baseline

This run validates the Program 6 starter K-means pipeline using a local
`data.dat` generated in the assignment-compatible binary format.

Environment and setup:

- WSL Ubuntu-24.04
- data generated with `scripts/generate_kmeans_data.py`
- generated data shape: `M=1000000`, `N=100`, `K=3`, `epsilon=0.1`
- data file size in WSL: about 767 MiB
- Python plotting dependencies installed in `prog6_kmeans/.venv`

Q1 result:

```text
Reading data.dat...
Running K-means with: M=1000000, N=100, K=3, epsilon=0.100000
[Total Time]: 4621.855 ms
```

An earlier same-setup run completed in `5036.867 ms`; the archived raw log is
from the second run, which was used for the final Q1/Q2 artifact copy.

Q2 artifacts:

- `start.log`
- `end.log`
- `start.png`
- `end.png`

The generated plots completed successfully. They show the initial clustered
state and the post-K-means cluster assignments after PCA projection to 2-D.
