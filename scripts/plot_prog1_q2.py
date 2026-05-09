#!/usr/bin/env python3
"""Plot prog1 Q2 speedup curves from CSVs in artifacts/experiments/prog1_q2/."""

import csv
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "artifacts" / "experiments" / "prog1" / "q2"


def load(csv_path):
    threads, runs, means = [], [], []
    with open(csv_path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            threads.append(int(row["threads"]))
            means.append(float(row["mean"]))
            runs.append([float(row[f"run{i}"]) for i in range(1, 6)])
    return threads, runs, means


def plot_single(view_id, threads, runs, means, out_path):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    # individual runs as light dots
    for i, t in enumerate(threads):
        ax.scatter([t] * len(runs[i]), runs[i], color="C0", alpha=0.35, s=25)
    ax.plot(threads, means, marker="o", color="C0", linewidth=2, label="mean of 5")
    ax.plot(threads, threads, "--", color="grey", alpha=0.6, label="ideal linear")
    ax.set_xlabel("Threads")
    ax.set_ylabel("Speedup over serial")
    ax.set_title(f"Prog1 contiguous-block decomposition — view {view_id}")
    ax.set_xticks(threads)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)


def plot_compare(t1, m1, t2, m2, out_path):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.plot(t1, m1, marker="o", linewidth=2, label="view 1")
    ax.plot(t2, m2, marker="s", linewidth=2, label="view 2")
    ax.plot(t1, t1, "--", color="grey", alpha=0.6, label="ideal linear")
    ax.set_xlabel("Threads")
    ax.set_ylabel("Speedup over serial (mean of 5)")
    ax.set_title("Prog1 contiguous-block decomposition — view 1 vs view 2")
    ax.set_xticks(t1)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)


def main():
    t1, r1, m1 = load(DATA / "view1.csv")
    t2, r2, m2 = load(DATA / "view2.csv")
    plot_single(1, t1, r1, m1, DATA / "speedup_view1.png")
    plot_single(2, t2, r2, m2, DATA / "speedup_view2.png")
    plot_compare(t1, m1, t2, m2, DATA / "speedup_compare.png")
    print("Wrote:")
    for p in ("speedup_view1.png", "speedup_view2.png", "speedup_compare.png"):
        print(f"  {DATA / p}")


if __name__ == "__main__":
    main()
