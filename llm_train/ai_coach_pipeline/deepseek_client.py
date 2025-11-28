from __future__ import annotations

import json
from typing import Dict, Optional

import requests

from .config import DeepSeekConfig


class DeepSeekClient:
    def __init__(self, config: DeepSeekConfig):
        self.config = config

    def coach_report(self, payload: Dict) -> Dict:
        headers = {
            "Authorization": f"Bearer {self.config.api_key}",
            "Content-Type": "application/json",
        }
        if self.config.extra_headers:
            headers.update(self.config.extra_headers)

        body = {
            "model": self.config.model,
            "messages": [
                {"role": "system", "content": self.config.system_prompt},
                {"role": "user", "content": json.dumps(payload, ensure_ascii=False)},
            ],
            "tools": [self.config.tool_schema],
            "tool_choice": self.config.tool_choice,
        }

        resp = requests.post(
            self.config.base_url,
            headers=headers,
            json=body,
            timeout=self.config.timeout_s,
        )
        resp.raise_for_status()
        data = resp.json()
        tool_call = data["choices"][0]["message"]["tool_calls"][0]
        arguments = tool_call["function"]["arguments"]
        return json.loads(arguments)
