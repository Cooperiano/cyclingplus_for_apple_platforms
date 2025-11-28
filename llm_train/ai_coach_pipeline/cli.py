from __future__ import annotations

import argparse
import json
from pathlib import Path

from .config import CoachConfig, DeepSeekConfig
from .payload_builder import build_payload, save_payload
from .deepseek_client import DeepSeekClient


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate DeepSeek-ready payloads and coach reports.")
    parser.add_argument("fit", help="Path to FIT file")
    parser.add_argument("--ftp", type=float, help="Functional Threshold Power")
    parser.add_argument("--lthr", type=int, help="Lactate threshold heart rate")
    parser.add_argument("--sleep", type=float, help="Sleep hours prior to ride")
    parser.add_argument("--rpe", type=int, help="Session RPE (1-10)")
    parser.add_argument("--atl", type=float, help="Acute training load")
    parser.add_argument("--ctl", type=float, help="Chronic training load")
    parser.add_argument("--tsb", type=float, help="Training stress balance")
    parser.add_argument("--mass", type=float, default=72.0, help="Athlete mass in kg")
    parser.add_argument("--bike-mass", type=float, default=8.0, help="Bike + gear mass in kg")
    parser.add_argument("--api-key", help="DeepSeek API key (optional if only building payload)")
    parser.add_argument("--model", default="deepseek-chat", help="DeepSeek model name")
    parser.add_argument("--out", type=Path, help="Optional path to save payload JSON")
    parser.add_argument("--report-out", type=Path, help="Optional path to save DeepSeek report JSON")
    parser.add_argument("--print", action="store_true", help="Print payload to stdout")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    coach_cfg = CoachConfig(
        ftp=args.ftp,
        lthr=args.lthr,
        athlete_mass_kg=args.mass,
        bike_mass_kg=args.bike_mass,
        sleep_hours=args.sleep,
        rpe=args.rpe,
        atl=args.atl,
        ctl=args.ctl,
        tsb=args.tsb,
    )
    payload = build_payload(args.fit, coach_cfg)

    if args.out:
        save_payload(payload, args.out)
        print(f"[coach] payload saved to {args.out}")

    if args.print:
        print(json.dumps(payload, ensure_ascii=False, indent=2))

    if args.api_key:
        deepseek = DeepSeekClient(
            DeepSeekConfig(api_key=args.api_key, model=args.model),
        )
        report = deepseek.coach_report(payload)
        if args.report_out:
            args.report_out.parent.mkdir(parents=True, exist_ok=True)
            args.report_out.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
            print(f"[coach] report saved to {args.report_out}")
        else:
            print(json.dumps(report, ensure_ascii=False, indent=2))
    elif not args.out:
        print("Payload built. Provide --api-key to request a DeepSeek report.")


if __name__ == "__main__":
    main()
