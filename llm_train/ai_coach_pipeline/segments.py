from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, List, Optional
import numpy as np
import pandas as pd

from .config import CoachConfig
from .sampling import serialize_segment
from .metrics import _get_numeric_altitude


@dataclass
class Segment:
    name: str
    start_idx: int
    end_idx: int
    stats: Dict[str, float]

    def extract(self, df: pd.DataFrame) -> pd.DataFrame:
        return df.iloc[self.start_idx : self.end_idx].copy()


def find_top_climbs(df: pd.DataFrame, count: int = 3, min_gain: float = 50.0) -> List[Segment]:
    altitude = _get_numeric_altitude(df)
    if altitude is None or "distance" not in df:
        return []
    alt_clean = altitude.fillna(method="ffill").fillna(method="bfill")
    climbs: List[Segment] = []
    start = None
    gain = 0.0

    for idx in range(1, len(df)):
        delta = alt_clean.iloc[idx] - alt_clean.iloc[idx - 1]
        if delta > 0:
            if start is None:
                start = idx - 1
            gain += delta
        else:
            if start is not None and gain >= min_gain:
                end = idx
                stats = summarize_segment(df, start, end, altitude=alt_clean)
                climbs.append(Segment(name=f"Climb-{len(climbs)+1}", start_idx=start, end_idx=end, stats=stats))
            start = None
            gain = 0

    climbs.sort(key=lambda seg: seg.stats.get("elev_gain_m", 0), reverse=True)
    return climbs[:count]


def summarize_segment(df: pd.DataFrame, start: int, end: int, altitude: Optional[pd.Series] = None) -> Dict[str, float]:
    seg = df.iloc[start:end]
    duration = seg["time_s"].iloc[-1] - seg["time_s"].iloc[0]
    stats = {
        "len_km": float((seg["distance"].iloc[-1] - seg["distance"].iloc[0]) / 1000),
        "duration_s": float(duration),
    }
    alt = altitude.iloc[start:end] if altitude is not None else _get_numeric_altitude(seg)
    if alt is not None:
        stats["elev_gain_m"] = float(alt.diff().clip(lower=0).sum())
        stats["vam"] = float((stats["elev_gain_m"] / (duration / 3600)) if duration else 0)
        stats["grad_pct"] = float(stats["elev_gain_m"] / (stats["len_km"] * 10) if stats["len_km"] else 0)
    if "power" in seg:
        stats["p_avg"] = float(seg["power"].mean())
        stats["p_max"] = float(seg["power"].max())
    if "heart_rate" in seg:
        stats["hr_avg"] = float(seg["heart_rate"].mean())
    if "cadence" in seg:
        stats["cadence_avg"] = float(seg["cadence"].mean())
    return stats


def detect_intervals(df: pd.DataFrame, ftp: Optional[float]) -> List[Segment]:
    if "power" not in df or ftp is None:
        return []
    normalized = df["power"] / ftp
    mask = normalized > 0.9
    intervals: List[Segment] = []
    start = None
    for idx, active in enumerate(mask):
        if active and start is None:
            start = idx
        elif not active and start is not None:
            if idx - start > 30:
                stats = summarize_segment(df, start, idx)
                intervals.append(Segment(name=f"Interval-{len(intervals)+1}", start_idx=start, end_idx=idx, stats=stats))
            start = None
    return intervals


def detect_anomalies(df: pd.DataFrame) -> List[Segment]:
    if "heart_rate" not in df:
        return []
    hr = df["heart_rate"]
    rolling = hr.rolling(window=120, min_periods=60).mean()
    drift = rolling.diff().fillna(0)
    threshold = drift.std() * 2
    anomalies = []
    start = None
    for idx, value in enumerate(drift):
        if value > threshold and start is None:
            start = idx
        elif value <= 0 and start is not None:
            stats = summarize_segment(df, start, idx)
            anomalies.append(Segment(name=f"HR-drift-{len(anomalies)+1}", start_idx=start, end_idx=idx, stats=stats))
            start = None
    return anomalies


def segment_payloads(df: pd.DataFrame, segments: List[Segment], sampling_cfg) -> List[Dict]:
    payloads = []
    altitude_master = _get_numeric_altitude(df)
    for seg in segments:
        data = seg.extract(df)
        times = data["time_s"].astype(float).values
        series = {}
        for col in ["altitude", "power", "heart_rate", "cadence", "speed"]:
            col_series = None
            if col == "altitude":
                if altitude_master is not None:
                    col_series = altitude_master.iloc[seg.start_idx : seg.end_idx]
                elif col in data:
                    col_series = pd.to_numeric(data[col], errors="coerce")
            elif col in data:
                col_series = pd.to_numeric(data[col], errors="coerce")

            if col_series is None:
                continue

            filled = col_series.ffill().bfill()
            if filled.isna().all():
                continue
            series[col_map(col)] = filled.to_numpy(dtype=float)
        serialized = serialize_segment(times, series, sampling_cfg)
        payloads.append(
            {
                "name": seg.name,
                "stats": seg.stats,
                "series": serialized,
            }
        )
    return payloads


def col_map(col: str) -> str:
    return {
        "altitude": "elev",
        "power": "p",
        "heart_rate": "hr",
        "cadence": "cad",
        "speed": "speed",
    }.get(col, col)
