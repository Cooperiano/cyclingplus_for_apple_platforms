#!/usr/bin/env python3
"""
chat_server.py

用 FastAPI 封装 Qwen-14B-Chat 为多会话对话 API。
支持新建/切换会话，保持历史。

启动：uvicorn chat_server:app --host 0.0.0.0 --port 8000
测试：curl -X POST "http://localhost:8000/chat" -H "Content-Type: application/json" -d '{"session_id": "sess1", "message": "你好"}'
"""
import os
import uuid
from typing import Dict, List

import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import AutoModelForCausalLM, AutoTokenizer

app = FastAPI()

# 全局模型加载
MODEL_PATH = "/home/julian/.cache/modelscope/hub/models/Qwen/Qwen-14B-Chat"
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, trust_remote_code=True, local_files_only=True)
model = AutoModelForCausalLM.from_pretrained(MODEL_PATH, trust_remote_code=True, local_files_only=True, device_map="auto")
model.config.use_cache = False
if hasattr(model, "generation_config"):
    model.generation_config.use_cache = False

# 会话存储：session_id -> history (list of dicts {role, text})
sessions: Dict[str, List[Dict[str, str]]] = {}

class ChatRequest(BaseModel):
    session_id: str
    message: str
    max_new_tokens: int = 128
    temperature: float = 0.8
    top_p: float = 0.95

class NewSessionResponse(BaseModel):
    session_id: str

@app.post("/chat", response_model=Dict[str, str])
def chat(req: ChatRequest):
    if req.session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found. Use /new_session first.")
    
    history = sessions[req.session_id]
    # 构建 prompt
    history_text = "\n".join([f"{'用户' if m['role'] == 'user' else '助手'}：{m['text']}" for m in history])
    prompt = f"下面是一段用户与助手的对话，注意角色前缀为“用户：”和“助手：”。请以助手身份回答用户的最后一条消息。\n\n{history_text}\n用户：{req.message}\n助手："
    
    inputs = tokenizer(prompt, return_tensors="pt")
    input_ids = inputs["input_ids"].to(model.device)
    attention_mask = inputs.get("attention_mask", torch.ones_like(input_ids)).to(model.device)
    
    with torch.no_grad():
        outputs = model.generate(
            input_ids=input_ids,
            attention_mask=attention_mask,
            max_new_tokens=req.max_new_tokens,
            do_sample=True,
            top_p=req.top_p,
            temperature=req.temperature,
            use_cache=False,
        )
    
    full_resp = tokenizer.decode(outputs[0], skip_special_tokens=True)
    assistant_reply = full_resp.split("助手：")[-1].strip() if "助手：" in full_resp else full_resp
    
    # 更新历史
    history.append({"role": "user", "text": req.message})
    history.append({"role": "assistant", "text": assistant_reply})
    
    return {"reply": assistant_reply}

@app.post("/new_session", response_model=NewSessionResponse)
def new_session():
    session_id = str(uuid.uuid4())
    sessions[session_id] = []
    return {"session_id": session_id}

@app.post("/switch_session")
def switch_session(session_id: str):
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found.")
    # 切换只是确认存在；客户端负责传递 session_id
    return {"message": f"Switched to session {session_id}"}

@app.get("/list_sessions")
def list_sessions():
    return {"sessions": list(sessions.keys())}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
