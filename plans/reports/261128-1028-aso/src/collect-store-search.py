#!/usr/bin/env python3
"""Collects live store-search evidence for the Vietnamese market.

For each query it records: App Store autocomplete hints, the App Store (vn, l=vi) search results page,
in both Vietnamese and English display languages, and the Google Play (hl=vi, gl=VN) search results page. It then fetches every Play app's detail page for
its title, short description, installs and rating count. Output: ../data/store-search.json.

Usage: python3 -I collect-store-search.py
These are the stores' public web pages, read without an account, so results are not personalised.
"""
import html
import json
import os
import plistlib
import re
import subprocess
import time
import urllib.parse

DATA = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data")
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36"

QUERIES = [
    "app chặn cuộc gọi rác", "ứng dụng chặn cuộc gọi rác", "app chặn số lạ", "chặn cuộc gọi ngoài danh bạ",
    "chặn cuộc gọi số lạ", "chặn cuộc gọi", "chặn số rác", "chặn cuộc gọi rác", "chặn số lạ", "chặn cuộc gọi lạ",
    "chặn cuộc gọi lừa đảo", "chặn số lừa đảo", "chặn spam", "chặn đầu số", "chặn số điện thoại",
    "chặn cuộc gọi quảng cáo", "chan cuoc goi", "chan so rac",
    "call blocker", "spam call blocker", "block unknown caller", "block spam calls",
]
HINT_SEEDS = ["chặn", "chặn c", "chặn cuộc gọi", "chặn s", "chặn số", "chan", "chan cuoc", "cuộc gọi", "lừa đảo",
              "số rác", "số lạ", "spam", "block", "call b", "call"]


def fetch(url, headers=()):
    cmd = ["curl", "-s", "-L", "--max-time", "40", "-A", UA]
    for h in headers:
        cmd += ["-H", h]
    return subprocess.run(cmd + [url], capture_output=True).stdout


def apple_hints(term):
    url = ("https://search.itunes.apple.com/WebObjects/MZSearchHints.woa/wa/hints?clientApplication=Software&term="
           + urllib.parse.quote(term))
    try:
        return [h["term"] for h in plistlib.loads(fetch(url, ["X-Apple-Store-Front: 143471-2,29"]))["hints"]]
    except Exception:
        return None


def walk(node, out):
    """Collects every result row. Rows are matched by their lockup, not by row kind: a row that carries an
    in-app event (Truecaller does) has a different kind and would otherwise be dropped."""
    if isinstance(node, dict):
        lk = node.get("lockup")
        if isinstance(lk, dict) and lk.get("$kind") == "MixedMediaLockup" and lk.get("adamId"):
            out.append({"id": lk["adamId"], "title": lk.get("title"), "subtitle": lk.get("subtitle"),
                        "rating": lk.get("rating"), "ratingCount": lk.get("ratingCount"),
                        "ad": node.get("resultType") not in (None, "content")})
        for v in node.values():
            walk(v, out)
    elif isinstance(node, list):
        for v in node:
            walk(v, out)


def apple_search(term, lang="vi"):
    """The Vietnamese storefront's search page, shown in Vietnamese (l=vi) or English (l=en)."""
    url = f"https://apps.apple.com/vn/iphone/search?l={lang}&term=" + urllib.parse.quote(term)
    page = fetch(url).decode("utf8", "replace")
    m = re.search(r'<script[^>]*id="serialized-server-data"[^>]*>(.*?)</script>', page, re.S)
    if not m:
        return None
    out = []
    walk(json.loads(m.group(1)), out)
    return out[:10]


def play_search(term):
    url = "https://play.google.com/store/search?c=apps&hl=vi&gl=VN&q=" + urllib.parse.quote(term)
    page = fetch(url).decode("utf8", "replace")
    ids = []
    for app_id in re.findall(r"details\?id=([a-zA-Z0-9._]+)", page):
        if app_id not in ids:
            ids.append(app_id)
    return ids[:10]


def play_detail(app_id):
    page = fetch(f"https://play.google.com/store/apps/details?id={app_id}&hl=vi&gl=VN").decode("utf8", "replace")

    def first(pattern):
        m = re.search(pattern, page, re.S)
        return html.unescape(re.sub(r"<[^>]+>", " ", m.group(1))).strip() if m else None
    return {
        "id": app_id,
        "title": first(r'itemprop="name"[^>]*>(.*?)</h1>') or first(r'<meta property="og:title" content="([^"]*)'),
        "short": first(r'<meta[^>]*itemprop="description"[^>]*content="([^"]*)') or first(r'<meta[^>]*name="description"[^>]*content="([^"]*)'),
        "longStart": (first(r'data-g-id="description"[^>]*>(.*?)</div>') or "")[:400],
        "installs": first(r">([\d.,]+ ?(?:N|Tr|T|K|M)?\+)</div><div[^>]*>Lượt tải xuống"),
        "ratings": first(r"([\d.,]+ ?(?:N|Tr)?) (?:bài )?đánh giá"),
        "developer": first(r'href="/store/apps/dev(?:eloper)?\?id=[^"]*"[^>]*><span>(.*?)</span>'),
    }


def main():
    out = {"collectedAt": time.strftime("%Y-%m-%d %H:%M %z"), "hints": {}, "appStore": {}, "appStoreEn": {}, "play": {}, "playApps": {}}
    for seed in HINT_SEEDS:
        out["hints"][seed] = apple_hints(seed)
        time.sleep(1)
    for q in QUERIES:
        out["appStore"][q] = apple_search(q)
        out["appStoreEn"][q] = apple_search(q, "en")
        out["play"][q] = play_search(q)
        print(q, len(out["appStore"][q] or []), len(out["play"][q] or []), flush=True)
        time.sleep(2)
    for app_id in sorted({i for ids in out["play"].values() for i in ids or []}):
        out["playApps"][app_id] = play_detail(app_id)
        time.sleep(1)
    with open(os.path.join(DATA, "store-search.json"), "w", encoding="utf8") as f:
        json.dump(out, f, ensure_ascii=False, indent=1)


if __name__ == "__main__":
    main()
