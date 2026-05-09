#!/usr/bin/env python3
"""Plot prog1 Q4 cyclic speedups + comparison against Q3 contiguous."""

import csv
from pathlib import Path
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parent.parent
Q3 = ROOT / "artifacts" / "experiments" / "prog1" / "q3"
Q4 = ROOT / "artifacts" / "experiments" / "prog1" / "q4"


def load(csv_path):
    threads, means = [], []
    with open(csv_path) as f:
        for row in csv.DictReader(f):
            threads.append(int(row["threads"]))
            means.append(float(row["mean"]))
    return threads, means


def plot_compare(view_id, t3, m3, t4, m4, out_path):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.plot(t3, m3, marker="s", linewidth=2, label="contiguous (Q3)", color="C1")
    ax.plot(t4, m4, marker="o", linewidth=2, label="cyclic (Q4)", color="C0")
    ax.plot(t4, t4, "--", color="grey", alpha=0.6, label="ideal linear")
    ax.set_xlabel("Threads")
    ax.set_ylabel("Speedup over serial (mean of 5)")
    ax.set_title(f"Prog1 — view {view_id}: contiguous vs cyclic decomposition")
    ax.set_xticks(t4)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)


def plot_cyclic_both(t1, m1, t2, m2, out_path):
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.plot(t1, m1, marker="o", linewidth=2, label="view 1")
    ax.plot(t2, m2, marker="s", linewidth=2, label="view 2")
    ax.plot(t1, t1, "--", color="grey", alpha=0.6, label="ideal linear")
    ax.set_xlabel("Threads")
    ax.set_ylabel("Speedup over serial (mean of 5)")
    ax.set_title("Prog1 cyclic decomposition — view 1 vs view 2")
    ax.set_xticks(t1)
    ax.grid(alpha=0.3)
    ax.legend()
    fig.tight_layout()
    fig.savefig(out_path, dpi=130)
    plt.close(fig)


def main():
    t3v1, m3v1 = load(Q3 / "view1_speedup.csv")
    t3v2, m3v2 = load(Q3 / "view2_speedup.csv")
    t4v1, m4v1 = load(Q4 / "view1_speedup.csv")
    t4v2, m4v2 = load(Q4 / "view2_speedup.csv")

    plot_compare(1, t3v1, m3v1, t4v1, m4v1, Q4 / "compare_view1.png")
    plot_compare(2, t3v2, m3v2, t4v2, m4v2, Q4 / "compare_view2.png")
    plot_cyclic_both(t4v1, m4v1, t4v2, m4v2, Q4 / "cyclic_both_views.png")
    print("Wrote plots to", Q4)


if __name__ == "__main__":
    main()
