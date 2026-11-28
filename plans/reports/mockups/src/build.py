#!/usr/bin/env python3
"""Inline the shared CSS/JS and one direction partial into a self-contained HTML file each.

Usage: python3 build.py   (writes ../a-la-chan.html, ../b-bang-dieu-khien.html, ../c-ban-phim.html)
"""
from pathlib import Path

SRC = Path(__file__).parent
OUT = SRC.parent
DIRECTIONS = {
    "a": ("a-la-chan.html", "A · Lá chắn", "Status first: one shield, one button, the list below."),
    "b": ("b-bang-dieu-khien.html", "B · Bảng điều khiển", "Bento grid. Tiles marked “Minh họa” show sample numbers, not real statistics."),
    "c": ("c-ban-phim.html", "C · Bàn phím", "Input first: the app opens on a keypad. Typing on your keyboard also works."),
}

PAGE = """<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title} — Chặn cuộc gọi mockup</title>
<style>
{css}
</style>
<script>
{js}
</script>
</head>
<body>
<div class="stage">
  <aside class="ctl">
    <h1>{title}</h1>
    <p>{blurb}</p>
    <p>Clickable mockup with sample data. Nothing here blocks real calls.</p>
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
{body}
{overlays}
  </div></div>
</div>
</body>
</html>
"""


def main() -> None:
    css = (SRC / "shared.css").read_text()
    js = (SRC / "shared.js").read_text()
    overlays = (SRC / "overlays.html").read_text()
    for key, (name, title, blurb) in DIRECTIONS.items():
        body = (SRC / f"{key}.html").read_text()
        (OUT / name).write_text(PAGE.format(title=title, blurb=blurb, css=css, js=js, body=body, overlays=overlays))
        print("wrote", OUT / name)


if __name__ == "__main__":
    main()
