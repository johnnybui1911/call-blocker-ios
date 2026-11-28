#!/usr/bin/env python3
"""Builds the icon concept mockups and home-screen previews as SVG, then PNG via rsvg-convert.

Usage: python3 build-icons.py            (writes ../icons and ../previews)
Colours come from the approved tokens (mockups-v3/src/tokens.json).
The shield path is the one used by the in-app animated shield (mockups-v3/src/core.js).
The handset is the Material Design "call" glyph (Apache 2.0); redraw or keep for the final asset.
"""
import base64
import os
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.dirname(HERE)
ICONS = os.path.join(OUT, "icons")
PREVIEWS = os.path.join(OUT, "previews")
COMPETITORS = os.path.join(OUT, "research", "icons")

SHIELD = "M66 4 120 24v46c0 36-23 60-54 74C35 130 12 106 12 70V24Z"
SHINE = "M66 4 12 24v46c0 20 7 36 19 49C28 96 30 54 66 4Z"
HANDSET = ("M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 "
           "3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 "
           "1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z")

MODES = {
    "dark": dict(bg0="#062414", bg1="#050A07", fg="#43F195", fgHi="#7CFFB8", on="#001C0B", core="#010804",
                 danger="#FF6A65", onDanger="#1B0605", shine="0.22"),
    "light": dict(bg0="#FFFFFF", bg1="#D1F1DB", fg="#008F38", fgHi="#12B152", on="#FFFFFF", core="#FFFFFF",
                  danger="#C90F1A", onDanger="#FFFFFF", shine="0.16"),
    # Tinted: iOS renders a greyscale icon and applies the user's tint. Simulated here with a blue tint
    # to prove each concept still reads without the brand green or the red.
    "tinted": dict(bg0="#2B2B2E", bg1="#0B0B0C", fg="#6FB1FF", fgHi="#B5D8FF", on="#0B0B0C", core="#0B0B0C",
                   danger="#EAF4FF", onDanger="#0B0B0C", shine="0.18"),
}


def shield_tf(s, cx, cy):
    return f"translate({cx - 66 * s:.1f} {cy - 74 * s:.1f}) scale({s})"


def handset(size, cx, cy, fill, flip=False):
    k = size / 18.0
    if flip:
        return f'<path transform="translate({cx + 12 * k:.1f} {cy - 12 * k:.1f}) scale({-k:.3f} {k:.3f})" d="{HANDSET}" fill="{fill}"/>'
    return f'<path transform="translate({cx - 12 * k:.1f} {cy - 12 * k:.1f}) scale({k:.3f})" d="{HANDSET}" fill="{fill}"/>'


def defs(p, uid):
    return (f'<defs><radialGradient id="bg{uid}" cx="50%" cy="28%" r="85%">'
            f'<stop offset="0" stop-color="{p["bg0"]}"/><stop offset="1" stop-color="{p["bg1"]}"/></radialGradient>'
            f'<linearGradient id="fg{uid}" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{p["fgHi"]}"/><stop offset="1" stop-color="{p["fg"]}"/></linearGradient></defs>')


def filled_shield(p, uid, s, cx, cy):
    return (f'<g transform="{shield_tf(s, cx, cy)}"><path d="{SHIELD}" fill="url(#fg{uid})"/>'
            f'<path d="{SHINE}" fill="#FFFFFF" opacity="{p["shine"]}"/></g>')


def concept_a(p, uid):
    """Shield + handset: the category convention, in the app's own green-on-black."""
    return filled_shield(p, uid, 5.6, 512, 520) + handset(350, 512, 476, p["on"])


def concept_b(p, uid):
    """Shield + handset + 'blocked' badge. The badge sits bottom-right so the iOS notification badge (top-right) never covers it."""
    badge = (f'<circle cx="778" cy="748" r="168" fill="{p["bg1"]}"/>'
             f'<circle cx="778" cy="748" r="136" fill="{p["danger"]}"/>'
             f'<path d="M722 692 834 804M834 692 722 804" stroke="{p["onDanger"]}" stroke-width="46" stroke-linecap="round" fill="none"/>')
    return filled_shield(p, uid, 5.3, 476, 492) + handset(320, 476, 452, p["on"]) + badge


def concept_c(p, uid):
    """Outlined shield, handset struck through: 'no calls get past'."""
    tf = shield_tf(5.5, 512, 520)
    shield = (f'<path transform="{tf}" d="{SHIELD}" fill="{p["core"]}" stroke="url(#fg{uid})" '
              f'stroke-width="11" stroke-linejoin="round"/>')
    slash = (f'<path d="M356 338 672 654" stroke="{p["core"]}" stroke-width="124" stroke-linecap="butt"/>'
             f'<path d="M356 338 672 654" stroke="{p["fg"]}" stroke-width="58" stroke-linecap="round"/>')
    return shield + handset(330, 512, 480, p["fg"], flip=True) + slash


def concept_d(p, uid):
    """Pulse rings: the in-app animated shield, frozen mid-pulse."""
    rings = "".join(
        f'<path transform="{shield_tf(s, 512, 520)}" d="{SHIELD}" fill="none" stroke="{p["fg"]}" '
        f'stroke-width="{w / s:.2f}" stroke-linejoin="round" opacity="{o}"/>'
        for s, w, o in ((5.35, 26, 0.55), (6.6, 22, 0.26)))
    return rings + filled_shield(p, uid, 4.1, 512, 520) + handset(256, 512, 488, p["on"])


CONCEPTS = [("a-shield-call", concept_a), ("b-shield-blocked", concept_b),
            ("c-shield-slash", concept_c), ("d-shield-pulse", concept_d)]


def icon_inner(fn, mode, uid):
    p = MODES[mode]
    return defs(p, uid) + f'<rect width="1024" height="1024" fill="url(#bg{uid})"/>' + fn(p, uid)


def icon_svg(fn, mode):
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">{icon_inner(fn, mode, "x")}</svg>'


def placed_icon(fn, mode, uid, x, y, size):
    """An icon clipped to the iOS corner radius, placed on a preview canvas."""
    r = 1024 * 0.2237
    return (f'<g transform="translate({x} {y}) scale({size / 1024:.5f})">'
            f'<clipPath id="clip{uid}"><rect width="1024" height="1024" rx="{r}" ry="{r}"/></clipPath>'
            f'<g clip-path="url(#clip{uid})">{icon_inner(fn, mode, uid)}</g></g>')


def data_uri(path):
    """rsvg-convert will not load files outside the SVG's own directory, so images are embedded."""
    kind = "png" if path.endswith(".png") else "jpeg"
    with open(path, "rb") as f:
        return f"data:image/{kind};base64," + base64.b64encode(f.read()).decode()


def placed_image(path, x, y, size, uid):
    r = size * 0.2237
    return (f'<clipPath id="ci{uid}"><rect x="{x}" y="{y}" width="{size}" height="{size}" rx="{r}"/></clipPath>'
            f'<image href="{data_uri(path)}" x="{x}" y="{y}" width="{size}" height="{size}" clip-path="url(#ci{uid})"/>')


FONT = "font-family=\"'SF Pro Text','Helvetica Neue',Helvetica,Arial,sans-serif\""


def label(text, cx, y, colour, size=33, weight=500):
    return f'<text x="{cx}" y="{y}" text-anchor="middle" {FONT} font-size="{size}" font-weight="{weight}" fill="{colour}">{text}</text>'


WALL = {
    "dark": ("#16202B", "#05070A", "#FFFFFF"),
    "light": ("#F6E9DC", "#BFD9EE", "#1C1C1E"),
    "tinted": ("#101216", "#000000", "#FFFFFF"),
}
NAMES = ["CallBye", "StopCall", "CallKick", "ByeCall"]


def home_screen(mode):
    """One home-screen page at 3x (1170 wide): a row of competitors, then the four concepts, each under a candidate name."""
    w, h, size, gap = 1170, 1420, 180, 87
    x0 = 96
    top, bottom, ink = WALL[mode]
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 {w} {h}" width="{w}" height="{h}">',
           f'<defs><linearGradient id="wall" x1="0" y1="0" x2="0.4" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>',
           f'<rect width="{w}" height="{h}" fill="url(#wall)"/>',
           f'<text x="96" y="120" {FONT} font-size="48" font-weight="600" fill="{ink}">9:41</text>']
    rows = [
        [("01-truecaller", "Truecaller"), ("02-hiya", "Hiya"), ("04-callcontrol", "Call Control"), ("09-sola", "Số Lạ")],
        [("07-cleancall", "CleanCall"), ("10-ntrust", "nTrust"), ("08-icallme", "iCallme"), ("14-chanso", "Chanso")],
    ]
    y = 200
    for ri, row in enumerate(rows):
        for ci, (f, name) in enumerate(row):
            x = x0 + ci * (size + gap)
            out.append(placed_image(os.path.join(COMPETITORS, f + ".jpg"), x, y, size, f"{ri}{ci}"))
            out.append(label(name, x + size / 2, y + size + 44, ink))
        y += size + 110
    for ci, (slug, fn) in enumerate(CONCEPTS):
        x = x0 + ci * (size + gap)
        out.append(placed_icon(fn, mode, f"h{ci}", x, y, size))
        out.append(label(NAMES[ci], x + size / 2, y + size + 44, ink))
        out.append(label("ABCD"[ci], x + size / 2, y + size + 96, ink, 30, 700))
    y += size + 170
    # The current icon, for comparison.
    cur = os.path.join(OUT, "..", "..", "..", "ios", "App", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png")
    out.append(placed_image(os.path.abspath(cur), x0, y, size, "cur"))
    out.append(label("Chặn cuộc g…", x0 + size / 2, y + size + 44, ink))
    out.append(label("hiện tại", x0 + size / 2, y + size + 96, ink, 30, 700))
    out.append("</svg>")
    return "".join(out)


def small_sizes():
    """Each concept at the sizes iOS really shows: home (60pt), Spotlight (40pt), Settings (29pt), notification (20pt), at 2x."""
    sizes = [(240, "120pt"), (120, "60pt home"), (80, "40pt"), (58, "29pt"), (40, "20pt")]
    w, row_h = 1500, 300
    h = row_h * len(CONCEPTS) * 1 + 90
    out = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" width="{w}" height="{h}">',
           f'<rect width="{w}" height="{h}" fill="#1B1B1D"/>']
    x = 150
    for size, name in sizes:
        out.append(label(name, x + size / 2, 50, "#FFFFFF", 22))
        x += size + 40
    out.append(label("light", 1010 + 60, 50, "#FFFFFF", 22))
    out.append(label("tinted", 1190 + 60, 50, "#FFFFFF", 22))
    for i, (slug, fn) in enumerate(CONCEPTS):
        y = 90 + i * row_h
        out.append(label("ABCD"[i], 70, y + 140, "#FFFFFF", 64, 700))
        x = 150
        for j, (size, _) in enumerate(sizes):
            out.append(placed_icon(fn, "dark", f"s{i}{j}", x, y + (240 - size) / 2, size))
            x += size + 40
        out.append(f'<rect x="980" y="{y - 10}" width="180" height="260" rx="16" fill="#E9EEF2"/>')
        out.append(placed_icon(fn, "light", f"sl{i}", 1010, y + 60, 120))
        out.append(placed_icon(fn, "tinted", f"st{i}", 1190, y + 60, 120))
    out.append("</svg>")
    return "".join(out)


def render(svg, path, width):
    svg_path = path[:-4] + ".svg"
    with open(svg_path, "w") as f:
        f.write(svg)
    subprocess.run(["rsvg-convert", "-w", str(width), "-o", path, svg_path], check=True)
    os.remove(svg_path)


def main():
    os.makedirs(ICONS, exist_ok=True)
    os.makedirs(PREVIEWS, exist_ok=True)
    for slug, fn in CONCEPTS:
        for mode in MODES:
            render(icon_svg(fn, mode), os.path.join(ICONS, f"icon-{slug}-{mode}-1024.png"), 1024)
    for mode in MODES:
        render(home_screen(mode), os.path.join(PREVIEWS, f"home-screen-{mode}.png"), 1170)
    render(small_sizes(), os.path.join(PREVIEWS, "small-sizes.png"), 1500)


if __name__ == "__main__":
    main()
