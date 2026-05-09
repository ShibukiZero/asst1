#!/usr/bin/env python3
"""Parse prog1 Q3 raw logs into a per-(threadcount, workerId) timing table.

For each thread count N in the log, collects every reported worker duration
(across all binary invocations and across the 5 internal repetitions inside
main.cpp), then summarises:

  - per-worker median ms (used as the worker's representative cost)
  - per-N fastest / slowest worker
  - imbalance ratio = slowest / fastest

Outputs a tidy CSV and a markdown table.
"""

import re
import statistics
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "artifacts" / "experiments" / "prog1" / "q3"

WORKER_RE = re.compile(
    r"\[worker (\d+)/(\d+) rows \d+\.\.\d+\]: ([0-9.]+) ms"
)
HDR_RE = re.compile(r"------- threads = (\d+) -------")


def parse_log(path):
    """Return dict[N][worker_id] = list[float ms]."""
    data = defaultdict(lambda: defaultdict(list))
    current_N = None
    with open(path) as f:
        for line in f:
            m = HDR_RE.search(line)
            if m:
                current_N = int(m.group(1))
                continue
            m = WORKER_RE.search(line)
            if m and current_N is not None:
                wid, ntotal, ms = int(m.group(1)), int(m.group(2)), float(m.group(3))
                if ntotal != current_N:
                    continue  # warmup or off
                data[current_N][wid].append(ms)
    return data


def summarise(data, view_id):
    rows_csv = [
        "threads,worker,n_samples,min_ms,median_ms,max_ms"
    ]
    summary_lines = [
        f"## View {view_id} — per-worker timing summary",
        "",
        "| Threads | Fastest worker (id, median ms) | Slowest worker (id, median ms) | Imbalance ratio |",
        "|---|---|---|---|",
    ]
    for N in sorted(data):
        worker_medians = {}
        for wid in sorted(data[N]):
            samples = data[N][wid]
            worker_medians[wid] = statistics.median(samples)
            rows_csv.append(
                f"{N},{wid},{len(samples)},"
                f"{min(samples):.3f},{statistics.median(samples):.3f},{max(samples):.3f}"
            )
        fast_id = min(worker_medians, key=worker_medians.get)
        slow_id = max(worker_medians, key=worker_medians.get)
        ratio = worker_medians[slow_id] / worker_medians[fast_id]
        summary_lines.append(
            f"| {N} | {fast_id}, {worker_medians[fast_id]:.1f} ms | "
            f"{slow_id}, {worker_medians[slow_id]:.1f} ms | {ratio:.2f}× |"
        )
    return rows_csv, summary_lines


def main():
    out_md = ["# Program 1 Q3 — per-worker timing analysis", ""]
    for view_id in (1, 2):
        log = DATA / f"view{view_id}_raw.log"
        if not log.exists():
            print(f"missing: {log}")
            continue
        data = parse_log(log)
        csv_rows, md_rows = summarise(data, view_id)
        (DATA / f"view{view_id}_per_worker.csv").write_text("\n".join(csv_rows) + "\n")
        out_md.extend(md_rows)
        out_md.append("")
    (DATA / "per_worker_summary.md").write_text("\n".join(out_md) + "\n")
    print("Wrote:")
    print(f"  {DATA / 'view1_per_worker.csv'}")
    print(f"  {DATA / 'view2_per_worker.csv'}")
    print(f"  {DATA / 'per_worker_summary.md'}")
    print()
    print("\n".join(out_md))


if __name__ == "__main__":
    main()
