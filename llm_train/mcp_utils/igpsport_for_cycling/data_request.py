#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import json
import argparse
import datetime as dt
from typing import Optional, Dict, Any, List, Tuple

import requests
from requests.adapters import HTTPAdapter, Retry
from dotenv import load_dotenv


BASE = "https://prod.zh.igpsport.com/service"

def make_session() -> requests.Session:
    s = requests.Session()
    s.headers.update({
        "user-agent": "igps-cn-export/1.0 (+requests)",
        "accept": "application/json, text/plain, */*",
        "content-type": "application/json",
        "origin": "https://login.passport.igpsport.cn",
        "referer": "https://login.passport.igpsport.cn/",
    })
    retries = Retry(total=5, backoff_factor=0.6,
                    status_forcelist=[429, 500, 502, 503, 504],
                    allowed_methods=["GET", "HEAD"])
    s.mount("http://", HTTPAdapter(max_retries=retries))
    s.mount("https://", HTTPAdapter(max_retries=retries))
    s.request_timeout = (10, 60)  # (connect, read)
    return s

def parse_date(s: Optional[str]) -> Optional[dt.date]:
    if not s:
        return None
    return dt.datetime.strptime(s, "%Y-%m-%d").date()

def ymd(date_str: Optional[str]) -> str:
    if not date_str:
        return time.strftime("unknown-%Y%m%d-%H%M%S")
    try:
        return dt.datetime.strptime(date_str[:10], "%Y-%m-%d").strftime("%Y-%m-%d")
    except Exception:
        return date_str.replace("/", "-").replace(" ", "_")

def safe_filename(date_hint: str, ride_id: int, title: Optional[str]) -> str:
    base = f"{ymd(date_hint)}-ride_{ride_id}"
    if title:
        t = "".join(ch if (ch.isascii() and ch.isalnum()) else "_" for ch in title)
        t = "_".join(filter(None, t.split("_")))
        if t:
            base += f"-{t[:40]}"
    return base + ".fit"

class IGPSCN:
    def __init__(self, username: str, password: str, bearer: Optional[str] = None, debug: bool = False):
        self.username = username
        self.password = password
        self.s = make_session()
        self.debug = debug
        if bearer:
            # 支持直接用已有 token（如果你从 Network 复制了）
            self.s.headers.update({"authorization": f"Bearer {bearer}"})

    def _dbg(self, *args):
        if self.debug:
            print("[debug]", *args, file=sys.stderr)

    def login(self) -> None:
        if "authorization" in self.s.headers:
            # 已有 token，先探测一下
            ok = self._probe()
            if ok:
                return
            # 有 token 但探测失败，继续走密码登录

        url = f"{BASE}/auth/account/login"
        data = {"username": self.username, "password": self.password, "appId": "igpsport-web"}
        r = self.s.post(url, data=json.dumps(data), timeout=self.s.request_timeout)
        self._dbg("login:", r.status_code)
        r.raise_for_status()
        j = r.json()
        if j.get("code") != 0 or "data" not in j:
            raise RuntimeError(f"登录失败：{j}")
        token = j["data"]["access_token"]
        self.s.headers.update({"authorization": f"Bearer {token}"})

        if not self._probe():
            raise RuntimeError("登录后探测失败，可能需要人工在网页确认后复制新的 Bearer token。")

    def _probe(self) -> bool:
        try:
            url = f"{BASE}/web-gateway/web-analyze/activity/queryMyActivity?pageNo=1&pageSize=1&reqType=0&sort=1"
            r = self.s.get(url, timeout=self.s.request_timeout)
            if r.status_code != 200:
                return False
            j = r.json()
            return j.get("code") == 0
        except Exception:
            return False

    def list_page(self, page_no: int, page_size: int = 20) -> Dict[str, Any]:
        url = f"{BASE}/web-gateway/web-analyze/activity/queryMyActivity"
        params = {"pageNo": page_no, "pageSize": page_size, "reqType": 0, "sort": 1}
        r = self.s.get(url, params=params, timeout=self.s.request_timeout)
        r.raise_for_status()
        return r.json()

    def detail(self, ride_id: int) -> Dict[str, Any]:
        url = f"{BASE}/web-gateway/web-analyze/activity/queryActivityDetail/{ride_id}"
        r = self.s.get(url, timeout=self.s.request_timeout)
        r.raise_for_status()
        return r.json()

    def download_fit_by_url(self, fit_url: str) -> bytes:
        # fitOssPath 可能在其他域名（如 app.zh.igpsport.com / OSS），单独请求
        r = self.s.get(fit_url, timeout=self.s.request_timeout, stream=True)
        r.raise_for_status()
        return r.content


def run(username: str, password: str, bearer: Optional[str],
        outdir: str, start_s: Optional[str], end_s: Optional[str],
        max_pages: int, sleep_s: float, use_detail: bool, debug: bool) -> Tuple[int, int]:
    os.makedirs(outdir, exist_ok=True)
    start = parse_date(start_s)
    end = parse_date(end_s)

    cli = IGPSCN(username, password, bearer=bearer, debug=debug)
    print("[*] Logging in (CN)...")
    cli.login()
    print("[+] Login ok")

    total, saved = 0, 0
    for page in range(1, max_pages + 1):
        j = cli.list_page(page_no=page, page_size=20)
        if j.get("code") != 0:
            print(f"[!] page {page} 返回异常：{j}", file=sys.stderr)
            break

        data = j.get("data") or {}
        rows: List[Dict[str, Any]] = data.get("rows") or []
        if not rows:
            print(f"[*] Page {page}: no items -> done.")
            break

        print(f"[*] Page {page}: {len(rows)} activities")

        for it in rows:
            total += 1
            ride_id = it.get("rideId") or it.get("id")
            start_time = it.get("startTime") or it.get("startTimeString") or ""
            title = it.get("title") or it.get("name") or "activity"

            # 过滤时间（按天）
            try:
                d = dt.datetime.strptime(str(start_time)[:10].replace(".", "-"), "%Y-%m-%d").date()
            except Exception:
                d = None
            if start and d and d < start:
                continue
            if end and d and d > end:
                continue

            if not ride_id:
                print("    ! skip item without rideId/id", file=sys.stderr)
                continue

            # 获取下载 URL
            # 先从列表尝试几个可能的字段名
            def _pick_fit_url(obj: Dict[str, Any]) -> Optional[str]:
                for k in ("fitOssPath", "fitUrl", "fitPath", "fitDownloadUrl", "fitOssUrl", "fit"):
                    v = (obj or {}).get(k)
                    if isinstance(v, str) and v.strip():
                        return v.strip()
                return None

            fit_url = _pick_fit_url(it)

            # 若列表没有，则查详情再取
            if not fit_url:
                dj = cli.detail(int(ride_id))
                if dj.get("code") == 0:
                    data = dj.get("data") or {}
                    fit_url = _pick_fit_url(data)

            if not (ride_id and fit_url):
                print(f"    ! skip ride {ride_id}: no fit url in list/detail", file=sys.stderr)
                continue

            fname = safe_filename(str(start_time), int(ride_id), str(title))
            path = os.path.join(outdir, fname)
            if os.path.exists(path) and os.path.getsize(path) > 0:
                print(f"    = exists, skip {path}")
                saved += 1
                continue

            # 下载 + 简单重试
            for attempt in range(1, 4):
                try:
                    blob = cli.download_fit_by_url(fit_url)
                    if not blob:
                        raise RuntimeError("empty body")
                    with open(path, "wb") as f:
                        f.write(blob)
                    print(f"    + saved {path}")
                    saved += 1
                    break
                except Exception as e:
                    print(f"    ! failed ride {ride_id} (try {attempt}/3): {e}", file=sys.stderr)
                    if attempt < 3:
                        time.sleep(1.2 * attempt)
                    else:
                        with open(path + ".fail.txt", "w") as f:
                            f.write(str(e))
                        print(f"    ! give up ride {ride_id}, wrote {path+'.fail.txt'}", file=sys.stderr)

        time.sleep(max(0.0, sleep_s))

    return total, saved


def main():
    load_dotenv()

    ap = argparse.ArgumentParser(description="Export FIT files from iGPSPORT China site.")
    ap.add_argument("--user", default=os.getenv("IGPS_USERNAME") or os.getenv("IGPSPORT_USERNAME"))
    ap.add_argument("--password", default=os.getenv("IGPS_PASSWORD") or os.getenv("IGPSPORT_PASSWORD"))
    # 如果你已经从网页复制了 Bearer token，也可以直接传入（会优先使用）
    ap.add_argument("--bearer", default=os.getenv("IGPS_BEARER"))
    ap.add_argument("--outdir", default=os.getenv("IGPS_OUTDIR", "downloads"))
    ap.add_argument("--start", default=os.getenv("IGPS_START"))  # YYYY-MM-DD
    ap.add_argument("--end", default=os.getenv("IGPS_END"))
    ap.add_argument("--max-pages", type=int, default=int(os.getenv("IGPS_MAX_PAGES", "50")))
    ap.add_argument("--sleep", type=float, default=float(os.getenv("IGPS_SLEEP", "0.6")))
    ap.add_argument("--detail", action="store_true", help="总是调用详情接口以拿 fitOssPath（当列表不返回时启用）")
    ap.add_argument("--debug", action="store_true")
    args = ap.parse_args()

    if not ((args.user and args.password) or args.bearer):
        print("请提供 IGPS_USERNAME/IGPS_PASSWORD（中国区登录）或 IGPS_BEARER（二选一即可）。", file=sys.stderr)
        sys.exit(2)

    total, saved = run(
        username=args.user,
        password=args.password,
        bearer=(args.bearer.split(None,1)[1] if args.bearer and args.bearer.lower().startswith("bearer ") else args.bearer),
        outdir=args.outdir,
        start_s=args.start,
        end_s=args.end,
        max_pages=args.max_pages,
        sleep_s=args.sleep,
        use_detail=args.detail,
        debug=args.debug,
    )

    print(f"[✓] Done. listed={total}, saved={saved}, outdir={args.outdir}")


if __name__ == "__main__":
    main()
