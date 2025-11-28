from __future__ import annotations

from dataclasses import dataclass, field
from typing import List, Optional


@dataclass
class SamplingConfig:
    """Controls downsampling and segment export."""

    target_freq_hz: float = 0.2  # uniform rate (5 s)
    burst_freq_hz: float = 1.0  # near change-points
    burst_window_s: int = 30
    douglas_peucker_epsilon_m: float = 2.0
    sax_window_s: int = 20
    sax_cardinality: int = 12
    max_segment_points: int = 400


@dataclass
class CoachConfig:
    """Athlete context and analysis knobs."""

    ftp: Optional[float] = None
    lthr: Optional[int] = None
    athlete_mass_kg: float = 72.0
    bike_mass_kg: float = 8.0
    crr: float = 0.004
    drivetrain_efficiency: float = 0.97
    sleep_hours: Optional[float] = None
    rpe: Optional[int] = None
    atl: Optional[float] = None
    ctl: Optional[float] = None
    tsb: Optional[float] = None
    preferred_segments: int = 3
    sampling: SamplingConfig = field(default_factory=SamplingConfig)


@dataclass
class DeepSeekConfig:
    """DeepSeek API configuration."""

    api_key: str
    model: str = "deepseek-chat"
    base_url: str = "https://api.deepseek.com/v1/chat/completions"
    timeout_s: int = 60
    extra_headers: Optional[dict] = None
    tool_choice: Optional[dict] = field(
        default_factory=lambda: {
            "type": "function",
            "function": {"name": "coach_report"},
        }
    )

    system_prompt: str = (
        "你是一名职业耐力骑行教练。你收到的是“事实计算后的数据摘要”，其中所有数值均已在外部函数中严格计算。"
        "请你基于这些事实：\n"
        "1) 评估本次训练完成度（量化、2-3个亮点）\n"
        "2) 指出3个可改进点（具体到阈值/区间或VAM目标）\n"
        "3) 给出“明日建议”（是否高强度？目标区间/时长/段速或VAM）\n"
        "4) 所有结论请附“证据条目”数组，引用相关字段（如 TSB、HR_drift、VAM、IF、TRIMP）\n"
        "若 mode=\"reduced\"，不要要求功率表头，用 HR 区间与 VAM 替代，并标注置信度。\n"
        "输出 JSON，字段：completion, highlights[], improvements[], tomorrow, evidence[], confidence"
    )

    tool_schema: dict = field(
        default_factory=lambda: {
            "type": "function",
            "function": {
                "name": "coach_report",
                "parameters": {
                    "type": "object",
                    "properties": {
                        "completion": {"type": "string"},
                        "highlights": {"type": "array", "items": {"type": "string"}},
                        "improvements": {"type": "array", "items": {"type": "string"}},
                        "tomorrow": {
                            "type": "object",
                            "properties": {
                                "intensity": {
                                    "type": "string",
                                    "enum": ["rest", "recovery", "endurance", "threshold", "vo2"],
                                },
                                "targets": {"type": "array", "items": {"type": "string"}},
                                "duration_min": {"type": "number"},
                            },
                            "required": ["intensity", "targets"],
                        },
                        "evidence": {"type": "array", "items": {"type": "string"}},
                        "confidence": {
                            "type": "string",
                            "enum": ["high", "medium", "low"],
                        },
                    },
                    "required": ["completion", "highlights", "improvements", "tomorrow", "evidence", "confidence"],
                },
            },
        }
    )
