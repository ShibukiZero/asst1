#!/usr/bin/env python3
"""Generate a local prog6_kmeans/data.dat-compatible dataset."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path

import numpy as np


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate a binary data.dat file for prog6_kmeans."
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("prog6_kmeans/data.dat"),
        help="Output path for the binary dataset.",
    )
    parser.add_argument("-m", "--points", type=int, default=1_000_000)
    parser.add_argument("-n", "--dimensions", type=int, default=100)
    parser.add_argument("-k", "--clusters", type=int, default=3)
    parser.add_argument("--epsilon", type=float, default=0.1)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--noise", type=float, default=0.5)
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=65_536,
        help="Number of points generated per write chunk.",
    )
    return parser.parse_args()


def nearest_centroid(points: np.ndarray, centroids: np.ndarray) -> np.ndarray:
    diffs = points[:, None, :] - centroids[None, :, :]
    distances = np.einsum("mkn,mkn->mk", diffs, diffs, optimize=True)
    return np.argmin(distances, axis=1).astype("<i4", copy=False)


def generate(args: argparse.Namespace) -> None:
    if args.points <= 0 or args.dimensions <= 0 or args.clusters <= 0:
        raise ValueError("points, dimensions, and clusters must be positive")
    if args.chunk_size <= 0:
        raise ValueError("chunk-size must be positive")

    rng = np.random.default_rng(args.seed)
    output = args.output
    output.parent.mkdir(parents=True, exist_ok=True)

    true_centers = rng.random((args.clusters, args.dimensions), dtype=np.float64)

    initial_centroids = np.empty((args.clusters, args.dimensions), dtype="<f8")
    initial_centroids[0] = rng.random(args.dimensions, dtype=np.float64)
    if args.clusters > 1:
        offsets = rng.uniform(
            low=-0.05,
            high=0.05,
            size=(args.clusters - 1, args.dimensions),
        )
        initial_centroids[1:] = initial_centroids[0] + offsets

    assignments = np.empty(args.points, dtype="<i4")

    with output.open("wb") as data_file:
        data_file.write(
            struct.pack(
                "<iiid",
                args.points,
                args.dimensions,
                args.clusters,
                args.epsilon,
            )
        )

        offset = 0
        while offset < args.points:
            count = min(args.chunk_size, args.points - offset)
            labels = rng.integers(args.clusters, size=count)
            noise = rng.normal(0.0, args.noise, size=(count, args.dimensions))
            points = (true_centers[labels] + noise).astype("<f8", copy=False)
            assignments[offset : offset + count] = nearest_centroid(
                points, initial_centroids
            )
            data_file.write(points.tobytes(order="C"))
            offset += count

        data_file.write(initial_centroids.tobytes(order="C"))
        data_file.write(assignments.tobytes(order="C"))

    size_mb = output.stat().st_size / (1024 * 1024)
    print(
        f"Wrote {output} ({size_mb:.1f} MiB): "
        f"M={args.points}, N={args.dimensions}, K={args.clusters}, "
        f"epsilon={args.epsilon}"
    )


def main() -> None:
    generate(parse_args())


if __name__ == "__main__":
    main()
