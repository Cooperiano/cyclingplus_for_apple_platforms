from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Iterable, List, Sequence, Tuple
import numpy as np

from .config import SamplingConfig


def douglas_peucker(points: Sequence[Tuple[float, float]], epsilon: float) -> List[Tuple[float, float]]:
    """Recursive Douglas–Peucker simplification."""

    if len(points) < 3:
        return list(points)

    (x1, y1), (x2, y2) = points[0], points[-1]
    line_vec = np.array([x2 - x1, y2 - y1])
    norm = np.linalg.norm(line_vec)
    if norm == 0:
        distances = np.linalg.norm(np.array(points) - np.array([x1, y1]), axis=1)
    else:
        line_unit = line_vec / norm
        diffs = np.array(points) - np.array([x1, y1])
        projections = diffs.dot(line_unit)
        closest = np.outer(projections, line_unit) + np.array([x1, y1])
        distances = np.linalg.norm(diffs - (closest - np.array([x1, y1])), axis=1)

    idx = int(np.argmax(distances))
    max_dist = distances[idx]

    if max_dist > epsilon:
        left = douglas_peucker(points[: idx + 1], epsilon)
        right = douglas_peucker(points[idx:], epsilon)
        return left[:-1] + right
    return [points[0], points[-1]]


def uniform_downsample(times: np.ndarray, values: Dict[str, np.ndarray], freq: float) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
    if freq <= 0:
        raise ValueError("freq must be >0")
    step = max(int(round(1 / freq)), 1)
    idx = np.arange(0, len(times), step)
    return times[idx], {k: v[idx] for k, v in values.items()}


def burst_enhance(times: np.ndarray, values: Dict[str, np.ndarray], change_points: Iterable[int], window_s: int) -> Tuple[np.ndarray, Dict[str, np.ndarray]]:
    cp_list = list(change_points) if change_points is not None else []
    if len(cp_list) == 0:
        return times, values
    sample_idx = set(range(len(times)))
    cp_set = set(int(cp) for cp in cp_list)
    dt = np.diff(times, prepend=times[0])
    approx_step = np.median(dt[dt > 0]) if np.any(dt > 0) else 1.0
    extra = int(max(round(window_s / approx_step), 1))
    for cp in cp_set:
        start = max(cp - extra, 0)
        end = min(cp + extra, len(times) - 1)
        sample_idx.update(range(start, end + 1))
    sorted_idx = np.array(sorted(sample_idx))
    return times[sorted_idx], {k: v[sorted_idx] for k, v in values.items()}


def sax_encode(series: np.ndarray, window: int, cardinality: int) -> List[float]:
    if window <= 0 or cardinality <= 1:
        return []
    if len(series) < window:
        return [float(np.mean(series))]
    sax = []
    for start in range(0, len(series), window):
        chunk = series[start : start + window]
        if len(chunk) == 0:
            continue
        mean = float(np.mean(chunk))
        sax.append(round(mean, 3))
    return sax[:cardinality]


def serialize_segment(times: np.ndarray, data: Dict[str, np.ndarray], config: SamplingConfig) -> Dict[str, List[float]]:
    """Combine uniform + burst sampling and apply limits."""

    if len(times) == 0:
        return {"t": [], "dt_s": int(1 / config.target_freq_hz), **{k: [] for k in data}}

    freq = config.target_freq_hz
    t_uniform, vals_uniform = uniform_downsample(times, data, freq)

    gradients = np.gradient(vals_uniform.get("elev", t_uniform), edge_order=1)
    change_points = np.where(np.abs(np.gradient(gradients)) > 0.5)[0]
    t_enhanced, vals_enhanced = burst_enhance(
        t_uniform,
        vals_uniform,
        change_points,
        config.burst_window_s,
    )

    max_points = config.max_segment_points
    if len(t_enhanced) > max_points:
        idx = np.linspace(0, len(t_enhanced) - 1, max_points).astype(int)
        t_enhanced = t_enhanced[idx]
        vals_enhanced = {k: v[idx] for k, v in vals_enhanced.items()}

    rel_time = (t_enhanced - t_enhanced[0]).astype(int)
    serialized = {"dt_s": int(round(1 / freq)), "t": rel_time.tolist()}
    for key, arr in vals_enhanced.items():
        serialized[key] = arr.round(3).tolist()
    return serialized
