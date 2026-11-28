#!/usr/bin/env python3
"""Build one self-contained HTML prototype per style from tokens.json + shared structure.

Usage: python3 build.py   (writes ../1-toi-gian.html, ../2-tuong-phan-cao.html, ../3-vi-tuong-tac.html)
"""
import json
from pathlib import Path

SRC = Path(__file__).parent
OUT = SRC.parent
FILES = {"toi-gian": ("1-toi-gian.html", "s1.html"), "tuong-phan-cao": ("2-tuong-phan-cao.html", "s2.html"), "vi-tuong-tac": ("3-vi-tuong-tac.html", "s3.html")}
COLOR_VARS = {"ink": "ink", "muted": "muted", "accent": "accent", "onAccent": "on-accent", "stateOn": "on", "stateOff": "offc", "surface": "card",
              "sheet": "sheet-bg", "field": "field-bg", "tagBg": "tag-bg", "tagInk": "tag-ink", "switchOff": "sw-off", "switchOn": "sw-on",
              "okBg": "live-ok-bg", "okInk": "live-ok-ink", "warnInk": "live-err", "scrim": "scrim", "toastBg": "toast-bg", "toastInk": "toast-ink"}
RADIUS_VARS = {"card": "r", "button": "r-btn", "field": "r-field", "sheet": "r-sheet"}


def css_vars(t: dict) -> str:
    c, out = t["color"], {}
    out["bg"] = c.get("bgGradient", c["bg"])
    out["bg-flat"] = c["bg"]
    out.update({COLOR_VARS[k]: v for k, v in c.items() if k in COLOR_VARS})
    out.update({RADIUS_VARS[k]: f"{v}px" for k, v in t["radius"].items()})
    out["font"] = t["font"]["web"]
    out["dur"] = f'{t["motion"]["fastMs"]}ms'
    out["dur-sheet"] = f'{t["motion"]["sheetMs"]}ms'
    out["ease"] = t["motion"]["easingCss"]
    out["btn-h"] = f'{t["size"]["buttonHeight"]}px'
    body = "".join(f"  --{k}: {v};\n" for k, v in out.items())
    return f".screen {{\n{body}}}\nbody.bare {{ background: {c['bg']}; }}\n"


PAGE = """<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{label} — Chặn cuộc gọi mockup</title>
<style>
{core}
/* Tokens for this style, generated from tokens.json */
{vars}</style>
<script>
{js}
</script>
</head>
<body>
<div class="stage">
  <aside class="ctl">
    <h1>{label}</h1>
    <p>{character}</p>
    <p>Layout A “Lá chắn”. Clickable mockup with sample data; nothing here blocks real calls.</p>
    <div class="grp"><span>State</span>
      <button data-act="state:home">Home, protection on</button>
      <button data-act="state:empty">Empty, no numbers yet</button>
      <button data-act="state:off">Protection off</button>
    </div>
    <div class="grp"><span>Add a number</span>
      <button data-act="add:02838234567">Full number 028 3823 4567</button>
      <button data-act="add:028888">Prefix 028888</button>
    </div>
    <div class="grp"><span>Compare</span><a href="index.html">All three side by side</a></div>
  </aside>
  <div class="phone"><div class="screen" data-prot="on">
    <div class="sb"><span>9:41</span><i>5G <b></b></i></div>
{layout}
{style}
{overlays}
  </div></div>
</div>
</body>
</html>
"""


def main() -> None:
    tokens = json.loads((SRC / "tokens.json").read_text())
    parts = {n: (SRC / n).read_text() for n in ("core.css", "core.js", "overlays.html", "layout-a.html")}
    for key, (name, style_file) in FILES.items():
        t = tokens["styles"][key]
        (OUT / name).write_text(PAGE.format(label=t["label"], character=t["motion"]["character"], core=parts["core.css"], vars=css_vars(t),
                                            js=parts["core.js"], layout=parts["layout-a.html"], style=(SRC / style_file).read_text(), overlays=parts["overlays.html"]))
        print("wrote", OUT / name)
    # Embed the tokens in the comparison page so its table always matches the prototypes.
    idx = OUT / "index.html"
    html = idx.read_text()
    start, end = html.index("const TOKENS = "), html.index(";\n  const frames")
    idx.write_text(html[:start] + "const TOKENS = " + json.dumps(tokens, ensure_ascii=False) + html[end:])


if __name__ == "__main__":
    main()
