from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

import numpy as np
import pandas as pd
from fitparse import FitFile

from .config import CoachConfig
from .metrics import ActivityMetrics, compute_core_metrics
from .segments import detect_anomalies, detect_intervals, find_top_climbs, segment_payloads


FIT_COLUMNS = ["timestamp", "position_lat", "position_long", "altitude", "distance", "speed", "heart_rate", "cadence", "power"]


def parse_fit(path: str) -> pd.DataFrame:
    fit = FitFile(path)
    records = []
    for record in fit.get_messages("record"):
        row = {}
        for field in record:
            row[field.name] = field.value
        records.append(row)
    df = pd.DataFrame(records)
    if df.empty:
        raise ValueError("FIT file contains no records")
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    df["time_s"] = (df["timestamp"] - df["timestamp"].iloc[0]).dt.total_seconds()
    if "position_lat" in df:
        df["lat"] = df["position_lat"] * (180 / 2**31)
        df["lon"] = df["position_long"] * (180 / 2**31)
    df = df.assign(
        power=df.get("power"),
        heart_rate=df.get("heart_rate"),
        cadence=df.get("cadence"),
        altitude=df.get("altitude"),
        distance=df.get("distance"),
        speed=df.get("speed"),
    )
    return df


def detect_modalities(df: pd.DataFrame) -> Dict[str, bool]:
    return {
        "power": df["power"].notna().any(),
        "cadence": df["cadence"].notna().any(),
        "hr": df["heart_rate"].notna().any(),
        "gps": df.get("lat", pd.Series(dtype=float)).notna().any(),
        "elev": df["altitude"].notna().any(),
    }


def build_payload(fit_path: str, coach_cfg: CoachConfig) -> Dict:
    df = parse_fit(fit_path)
    metrics = compute_core_metrics(df, coach_cfg)

    climbs = find_top_climbs(df, count=coach_cfg.preferred_segments)
    intervals = detect_intervals(df, coach_cfg.ftp)
    anomalies = detect_anomalies(df)
    segments = climbs + intervals[:2] + anomalies[:1]
    segment_data = segment_payloads(df, segments, coach_cfg.sampling)

    payload = {
        "mode": metrics.mode,
        "meta": metrics.meta,
        "modalities": metrics.modality_flags,
        "physio": metrics.physio,
        "hr": metrics.hr,
        "cadence": metrics.cadence,
        "zones_pct": metrics.zones_pct,
        "load": metrics.load,
        "terrain": metrics.terrain,
        "est": metrics.estimates,
        "context": {
            "sleep_h": coach_cfg.sleep_hours,
            "rpe": coach_cfg.rpe,
        },
        "segments": segment_data,
    }
    return _to_native(payload)


def save_payload(payload: Dict, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(_to_native(payload), ensure_ascii=False, indent=2), encoding="utf-8")


def _to_native(value):
    if isinstance(value, dict):
        return {k: _to_native(v) for k, v in value.items()}
    if isinstance(value, list):
        return [_to_native(v) for v in value]
    if isinstance(value, tuple):
        return [_to_native(v) for v in value]
    if isinstance(value, np.generic):
        return value.item()
    if isinstance(value, (np.ndarray, pd.Series)):
        return _to_native(value.tolist())
    return value
