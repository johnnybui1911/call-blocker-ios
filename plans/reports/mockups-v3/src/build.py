#!/usr/bin/env python3
"""Build the self-contained Hợp nhất prototype and the comparison page from tokens.json.

Also checks every contrast pair listed in tokens.json for both modes and fails if one is below its target.
Usage: python3 build.py   (writes ../hop-nhat.html and refreshes the tokens embedded in ../index.html)
"""
import json
import re
import sys
from pathlib import Path

SRC = Path(__file__).parent
OUT = SRC.parent
# Aliases from the shared structure's variable names to the semantic tokens.
ALIASES = {"bg": "linear-gradient(180deg, var(--c-bg-top) 0%, var(--c-bg) 46%)", "bg-flat": "var(--c-bg)", "ink": "var(--c-ink)", "muted": "var(--c-muted)",
           "accent": "var(--c-accent)", "on-accent": "var(--c-on-accent)", "on": "var(--c-protected)", "offc": "var(--c-danger)", "card": "var(--c-surface)",
           "sheet-bg": "var(--c-sheet)", "field-bg": "var(--c-field)", "tag-bg": "var(--c-tag-bg)", "tag-ink": "var(--c-tag-ink)", "sw-off": "var(--c-switch-off)",
           "sw-on": "var(--c-accent)", "live-ok-bg": "var(--c-ok-bg)", "live-ok-ink": "var(--c-ok-ink)", "live-err": "var(--c-warn-text)", "scrim": "var(--c-scrim)",
           "toast-bg": "var(--c-toast-bg)", "toast-ink": "var(--c-toast-ink)"}


def kebab(name: str) -> str:
    return re.sub(r"([A-Z])", lambda m: "-" + m.group(1).lower(), name)


def luminance(hex_color: str) -> float:
    v = [int(hex_color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
    v = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in v]
    return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2]


def contrast(a: str, b: str) -> float:
    hi, lo = sorted([luminance(a), luminance(b)], reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def check_contrast(tokens: dict) -> list:
    rows, failed = [], False
    for mode, colors in tokens["color"].items():
        for fg, bg, target in tokens["contrastPairs"]:
            ratio = contrast(colors[fg], colors[bg])
            rows.append({"mode": mode, "fg": fg, "bg": bg, "target": target, "ratio": round(ratio, 2)})
            if ratio < target:
                failed = True
                print(f"CONTRAST FAIL {mode}: {fg} on {bg} = {ratio:.2f} (needs {target})")
    if failed:
        sys.exit(1)
    return rows


def css_vars(tokens: dict) -> str:
    sh, out = tokens["shared"], ""
    for mode, colors in tokens["color"].items():
        body = "".join(f"  --c-{kebab(k)}: {v};\n" for k, v in colors.items())
        out += f'html[data-mode="{mode}"] {{\n{body}}}\n'
    shared = dict(ALIASES)
    shared.update({"r": f'{sh["radius"]["card"]}px', "r-btn": f'{sh["radius"]["button"]}px', "r-field": f'{sh["radius"]["field"]}px', "r-sheet": f'{sh["radius"]["sheet"]}px',
                   "font": sh["font"]["web"], "dur": f'{sh["motion"]["fastMs"]}ms', "dur-sheet": f'{sh["motion"]["sheetMs"]}ms', "ease": sh["motion"]["easingCss"],
                   "btn-h": f'{sh["size"]["buttonHeight"]}px'})
    return out + ".screen {\n" + "".join(f"  --{k}: {v};\n" for k, v in shared.items()) + "}\n"


PAGE = """<!doctype html>
<html lang="vi" data-mode="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="color-scheme" content="dark light">
<title>Hợp nhất — Chặn cuộc gọi mockup</title>
<script>
  // Set the mode before first paint: ?mode= wins, otherwise the system setting.
  document.documentElement.dataset.mode = new URLSearchParams(location.search).get('mode') || (matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
</script>
<style>
{core}
/* Tokens for both modes, generated from tokens.json */
{vars}</style>
<script>
{js}
</script>
</head>
<body>
<div class="stage">
  <aside class="ctl">
    <h1>Hợp nhất</h1>
    <p>Layout A “Lá chắn”, micro-interactions, round-one green and red, in dark and light.</p>
    <p>Clickable mockup with sample data; nothing here blocks real calls.</p>
    <div class="grp"><span>Appearance</span>
      <button data-act="mode:system">Follow system</button>
      <button data-act="mode:dark">Dark</button>
      <button data-act="mode:light">Light</button>
    </div>
    <div class="grp"><span>State</span>
      <button data-act="state:home">Home, protection on</button>
      <button data-act="state:empty">Empty, no numbers yet</button>
      <button data-act="state:off">Protection off</button>
    </div>
    <div class="grp"><span>Add a number</span>
      <button data-act="add:02838234567">Full number 028 3823 4567</button>
      <button data-act="add:028888">Prefix 028888</button>
    </div>
    <div class="grp"><span>Compare</span><a href="index.html">Dark and light side by side</a></div>
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
    rows = check_contrast(tokens)
    parts = {n: (SRC / n).read_text() for n in ("core.css", "core.js", "overlays.html", "layout-a.html", "style.html")}
    (OUT / "hop-nhat.html").write_text(PAGE.format(core=parts["core.css"], vars=css_vars(tokens), js=parts["core.js"], layout=parts["layout-a.html"],
                                                  style=parts["style.html"], overlays=parts["overlays.html"]))
    print("wrote", OUT / "hop-nhat.html")
    idx = OUT / "index.html"
    if idx.exists():
        html = idx.read_text()
        start, end = html.index("const DATA = "), html.index(";\n  const frames")
        idx.write_text(html[:start] + "const DATA = " + json.dumps({"tokens": tokens, "contrast": rows}, ensure_ascii=False) + html[end:])
        print("refreshed", idx)
    print("contrast: all", len(rows), "pairs pass; lowest", min(rows, key=lambda r: r["ratio"] / r["target"]))


if __name__ == "__main__":
    main()
