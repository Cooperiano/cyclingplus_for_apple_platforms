from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Optional, Tuple
import numpy as np
import pandas as pd

from .config import CoachConfig


@dataclass
class ActivityMetrics:
    mode: str
    meta: Dict[str, float]
    physio: Dict[str, float]
    hr: Dict[str, float]
    cadence: Dict[str, float]
    zones_pct: Dict[str, float]
    load: Dict[str, float]
    terrain: Dict[str, float]
    estimates: Dict[str, float]
    modality_flags: Dict[str, bool]


def rolling_power(df: pd.DataFrame, window: int = 30) -> pd.Series:
    power = df["power"].fillna(0)
    return power.pow(4).rolling(window=window, min_periods=window).mean().pow(0.25)


def _get_numeric_altitude(df: pd.DataFrame) -> Optional[pd.Series]:
    if "altitude" not in df:
        return None
    altitude = pd.to_numeric(df["altitude"], errors="coerce")
    if altitude.isna().all():
        return None
    return altitude


def compute_core_metrics(df: pd.DataFrame, config: CoachConfig) -> ActivityMetrics:
    duration_s = float(df["time_s"].iloc[-1] - df["time_s"].iloc[0])
    distance_km = float(df["distance"].iloc[-1] / 1000) if "distance" in df else np.nan
    altitude = _get_numeric_altitude(df)
    elev_gain = float(altitude.diff().clip(lower=0).sum()) if altitude is not None else np.nan

    has_power = df["power"].notna().any()
    has_cadence = df["cadence"].notna().any()
    has_hr = df["heart_rate"].notna().any()

    np_value = float(rolling_power(df).dropna().mean()) if has_power else None
    ftp = config.ftp or np_value or 250
    if_value = float(np_value / ftp) if np_value and ftp else None
    tss = float(((duration_s * np_value * if_value) / (ftp * 3600)) * 100) if np_value and if_value else None
    kj = None
    if has_power:
        dt = df["time_s"].diff().fillna(0).clip(lower=0)
        work_j = (df["power"].fillna(0) * dt).sum()
        kj = float(work_j / 1000)

    vi = float(np_value / max(df["power"].mean(), 1)) if has_power and np_value else None

    hr_avg = float(df["heart_rate"].mean()) if has_hr else None
    hr_max = float(df["heart_rate"].max()) if has_hr else None
    hr_drift = compute_hr_drift(df) if has_hr and has_power else None

    cadence_stats = {}
    if has_cadence:
        cadence_stats = {
            "avg": float(df["cadence"].mean()),
            "stdev": float(df["cadence"].std()),
            "low_rpm_pct": float((df["cadence"] < 75).mean() * 100),
        }

    zones = compute_power_zones(df, ftp) if has_power else compute_hr_zones(df, config.lthr)
    load = compute_load_metrics(df, config, np_value=np_value, if_value=if_value, tss=tss)

    terrain = {}
    if altitude is not None:
        vam = compute_vam(df, altitude)
        terrain = {"vam_main": vam}

    estimates = {}
    if not has_power and altitude is not None:
        estimates = estimate_climb_power(df, config, altitude)

    modality_flags = {"power": has_power, "cadence": has_cadence, "hr": has_hr, "gps": "lat" in df}

    physio = {}
    if has_power:
        physio = {
            "ftp": ftp,
            "np": np_value,
            "if": if_value,
            "tss": tss,
            "kJ": kj,
            "vi": vi,
        }

    hr_block = {}
    if has_hr:
        hr_block = {"avg": hr_avg, "max": hr_max, "drift_pct": hr_drift}

    return ActivityMetrics(
        mode="full" if has_power else "reduced",
        meta={"duration_s": duration_s, "distance_km": distance_km, "elev_gain_m": elev_gain},
        physio=physio,
        hr=hr_block,
        cadence=cadence_stats,
        zones_pct=zones,
        load=load,
        terrain=terrain,
        estimates=estimates,
        modality_flags=modality_flags,
    )


def compute_power_zones(df: pd.DataFrame, ftp: float) -> Dict[str, float]:
    if ftp is None or ftp <= 0:
        return {}
    power = df["power"].clip(lower=0)
    total = len(power)
    bins = {
        "z1": (0, 0.55),
        "z2": (0.55, 0.75),
        "z3": (0.75, 0.9),
        "z4": (0.9, 1.05),
        "z5": (1.05, 1.2),
        "z6": (1.2, np.inf),
    }
    pct = {}
    for zone, (lo, hi) in bins.items():
        mask = (power / ftp >= lo) & (power / ftp < hi)
        pct[zone] = float(mask.mean() * 100) if total else 0.0
    return pct


def compute_hr_zones(df: pd.DataFrame, lthr: Optional[int]) -> Dict[str, float]:
    if lthr is None:
        return {}
    hr = df["heart_rate"].dropna()
    if hr.empty:
        return {}
    total = len(hr)
    pct = {}
    boundaries = {
        "z1": (0, 0.7),
        "z2": (0.7, 0.8),
        "z3": (0.8, 0.9),
        "z4": (0.9, 1.0),
        "z5": (1.0, 1.1),
    }
    for zone, (lo, hi) in boundaries.items():
        mask = (hr / lthr >= lo) & (hr / lthr < hi)
        pct[zone] = float(mask.mean() * 100) if total else 0.0
    return pct


def compute_hr_drift(df: pd.DataFrame) -> float:
    halfway = df["time_s"].iloc[0] + (df["time_s"].iloc[-1] - df["time_s"].iloc[0]) / 2
    first = df[df["time_s"] <= halfway]
    second = df[df["time_s"] > halfway]
    if first.empty or second.empty:
        return 0.0
    ratio1 = first["heart_rate"].mean() / max(first["power"].mean(), 1)
    ratio2 = second["heart_rate"].mean() / max(second["power"].mean(), 1)
    return float(((ratio2 - ratio1) / ratio1) * 100)


def compute_vam(df: pd.DataFrame, altitude: Optional[pd.Series] = None) -> float:
    alt = altitude if altitude is not None else _get_numeric_altitude(df)
    if alt is None:
        return float("nan")
    elev_gain = alt.diff().clip(lower=0).sum()
    duration_h = (df["time_s"].iloc[-1] - df["time_s"].iloc[0]) / 3600
    return float((elev_gain / duration_h) if duration_h > 0 else 0)


def estimate_climb_power(df: pd.DataFrame, config: CoachConfig, altitude: Optional[pd.Series] = None) -> Dict[str, float]:
    alt = altitude if altitude is not None else _get_numeric_altitude(df)
    if alt is None:
        return {"p_climb_est_w": np.nan, "confidence": "low"}
    mass = config.athlete_mass_kg + config.bike_mass_kg
    elev_gain = alt.diff().clip(lower=0)
    dt = df["time_s"].diff().fillna(1)
    v_vert = elev_gain / dt.replace(0, 1)
    g = 9.80665
    grav_work = mass * g * v_vert
    rolling = config.crr * mass * g * df.get("speed", 0)
    efficiency = getattr(config, "drivetrain_efficiency", 0.97)
    p = (grav_work + rolling) / max(efficiency, 0.5)
    return {"p_climb_est_w": float(np.nanmean(p)), "confidence": "medium"}


def compute_load_metrics(df: pd.DataFrame, config: CoachConfig, np_value: Optional[float], if_value: Optional[float], tss: Optional[float]) -> Dict[str, float]:
    atl = config.atl or np.nan
    ctl = config.ctl or np.nan
    tsb = config.tsb if config.tsb is not None else (ctl - atl if not np.isnan(ctl) and not np.isnan(atl) else np.nan)
    trimp = compute_trimp(df, config.lthr) if config.lthr else None
    load = {}
    if tss is not None:
        load["tss"] = tss
    if trimp is not None:
        load["trimp"] = trimp
    if not np.isnan(atl):
        load["atl"] = atl
    if not np.isnan(ctl):
        load["ctl"] = ctl
    if not np.isnan(tsb):
        load["tsb"] = tsb
    return load


def compute_trimp(df: pd.DataFrame, lthr: Optional[int]) -> Optional[float]:
    if lthr is None:
        return None
    hr = df["heart_rate"].dropna()
    if hr.empty:
        return None
    minutes = (df["time_s"].iloc[-1] - df["time_s"].iloc[0]) / 60
    intensity = np.clip((hr / lthr) - 1, 0, None)
    trimp = float(minutes * np.mean(intensity) * 100)
    return trimp
