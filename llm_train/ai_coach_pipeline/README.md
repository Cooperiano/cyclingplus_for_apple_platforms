# AI Coach Pipeline

This module implements the sampling, compression, and DeepSeek handoff strategy described in the “AI 深度指导” spec.

## Features

- FIT parsing via `fitparse`.
- Local computation of NP/IF/TSS, TRIMP, HR drift, VAM, ATL/CTL/TSB, CP-friendly stats.
- Segment selection for climbs, threshold intervals, and HR anomalies.
- Adaptive downsampling (uniform 0.2 Hz + Douglas–Peucker inspired bursts) capped to ~400 points/segment.
- Payload builder that emits the compact JSON required by DeepSeek.
- DeepSeek client enforcing the `coach_report` tool schema and the provided system prompt.
- CLI for offline review or instant cloud coaching.

## Usage

```bash
python -m ai_coach_pipeline.cli /Users/juliancooper/Desktop/Projects_for_macos/cyclingplus/llm_train/downloads/2025.11.01-ride_41589174.fit \
  --ftp 270 --lthr 172 --sleep 6.5 --rpe 7 \
  --atl 85 --ctl 73 --tsb -12 \
  --out payload.json \
  --api-key $DEEPSEEK_API_KEY \
  --report-out report.json
```

- Omit `--api-key` to only build the payload; provide it to fetch the DeepSeek response.
- Use `--print` to inspect the payload.

## Integration

- Call `build_payload(fit_path, CoachConfig(...))` from Swift or Python services before hitting DeepSeek.
- Persist both the payload and the LLM response to enable RAG over prior workouts.

## Dependencies

- `fitparse`, `pandas`, `numpy`, `requests`

Install via:

```bash
pip install fitparse pandas numpy requests
```
