"""
AI coaching pipeline utilities for CyclingPlus.

This package provides:
  * FIT parsing helpers
  * Metric computations (NP/IF/TSS, TRIMP, HR drift, VAM, ATL/CTL/TSB)
  * Segment selection and adaptive downsampling routines
  * Payload assembly for DeepSeek
  * A lightweight DeepSeek client that enforces the coach_report schema
"""

from .config import CoachConfig, SamplingConfig, DeepSeekConfig
from .payload_builder import build_payload
from .deepseek_client import DeepSeekClient

__all__ = [
    "CoachConfig",
    "SamplingConfig",
    "DeepSeekConfig",
    "build_payload",
    "DeepSeekClient",
]
