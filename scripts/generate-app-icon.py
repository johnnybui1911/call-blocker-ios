#!/usr/bin/env python3
"""Generate the app icon (shield with pulse rings and a handset) from design/tokens.json.

Writes ios/App/Assets.xcassets/AppIcon.appiconset:
  AppIcon.png         default, shown in every appearance that has no variant: the dark palette
  AppIcon-dark.png    iOS 18 dark appearance: the same artwork, so iOS does not darken it itself
  AppIcon-tinted.png  iOS 18 tinted appearance: greyscale, iOS applies the user's tint
and design/app-icon/app-icon-light-1024.png, the light palette version. iOS has no light slot
when the default is the dark artwork, so that file is kept for store art and Android only.

All PNGs are 1024x1024 with no alpha channel, as App Store Connect requires.

Usage:
  python3 scripts/generate-app-icon.py           write the icons (needs rsvg-convert and magick)
  python3 scripts/generate-app-icon.py --check   fail if the committed icons have alpha or a wrong size

The shield is the path drawn by ios/App/ShieldView.swift. The handset is the Material Design
"call" glyph (Apache License 2.0).
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "design" / "tokens.json"
ICONSET = ROOT / "ios" / "App" / "Assets.xcassets" / "AppIcon.appiconset"
LIGHT_OUT = ROOT / "design" / "app-icon" / "app-icon-light-1024.png"

SHIELD = "M66 4 120 24v46c0 36-23 60-54 74C35 130 12 106 12 70V24Z"
SHINE = "M66 4 12 24v46c0 20 7 36 19 49C28 96 30 54 66 4Z"
HANDSET = ("M6.62 10.79c1.44 2.83 3.76 5.14 6.59 6.59l2.2-2.2c.27-.27.67-.36 1.02-.24 1.12.37 2.33.57 "
           "3.57.57.55 0 1 .45 1 1V20c0 .55-.45 1-1 1-9.39 0-17-7.61-17-17 0-.55.45-1 1-1h3.5c.55 0 1 .45 "
           "1 1 0 1.25.2 2.45.57 3.57.11.35.03.74-.25 1.02l-2.2 2.2z")

# The shield's top highlight is not a token: it is `protected` lightened for the gradient.
HIGHLIGHT = {"dark": "#7CFFB8", "light": "#12B152"}
TINTED = dict(bg0="#2B2B2E", bg1="#000000", fg="#C9C9C9", fgHi="#FFFFFF", on="#000000", shine="0.18")


def palette(mode: str) -> dict:
    c = json.loads(TOKENS.read_text())["color"][mode]
    if mode == "dark":
        return dict(bg0=c["bgTop"], bg1=c["bg"], fg=c["protected"], fgHi=HIGHLIGHT[mode], on=c["onAccent"], shine="0.22")
    return dict(bg0=c["surface"], bg1=c["bgTop"], fg=c["protected"], fgHi=HIGHLIGHT[mode], on=c["onAccent"], shine="0.16")


def shield_transform(scale: float, cx: float = 512, cy: float = 520) -> str:
    return f"translate({cx - 66 * scale:.1f} {cy - 74 * scale:.1f}) scale({scale})"


def svg(p: dict) -> str:
    rings = "".join(
        f'<path transform="{shield_transform(s)}" d="{SHIELD}" fill="none" stroke="{p["fg"]}" '
        f'stroke-width="{width / s:.2f}" stroke-linejoin="round" opacity="{opacity}"/>'
        for s, width, opacity in ((5.35, 26, 0.55), (6.6, 22, 0.26)))
    k = 256 / 18.0
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">'
        '<defs><radialGradient id="bg" cx="50%" cy="28%" r="85%">'
        f'<stop offset="0" stop-color="{p["bg0"]}"/><stop offset="1" stop-color="{p["bg1"]}"/></radialGradient>'
        '<linearGradient id="fg" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{p["fgHi"]}"/><stop offset="1" stop-color="{p["fg"]}"/></linearGradient></defs>'
        '<rect width="1024" height="1024" fill="url(#bg)"/>'
        f'{rings}<g transform="{shield_transform(4.1)}"><path d="{SHIELD}" fill="url(#fg)"/>'
        f'<path d="{SHINE}" fill="#FFFFFF" opacity="{p["shine"]}"/></g>'
        f'<path transform="translate({512 - 12 * k:.1f} {488 - 12 * k:.1f}) scale({k:.3f})" d="{HANDSET}" fill="{p["on"]}"/>'
        '</svg>')


def render(p: dict, out: Path, grey: bool = False) -> None:
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        source, raw = Path(tmp) / "icon.svg", Path(tmp) / "icon.png"
        source.write_text(svg(p))
        subprocess.run(["rsvg-convert", "-w", "1024", "-h", "1024", "-o", str(raw), str(source)], check=True)
        # Flatten and drop the alpha channel; App Store Connect rejects icons that have one.
        colour = ["-colorspace", "Gray", "-type", "Grayscale"] if grey else ["-type", "TrueColor"]
        subprocess.run(["magick", str(raw), "-background", p["bg1"], "-alpha", "remove", "-alpha", "off",
                        *colour, "-strip", f"PNG24:{out}" if not grey else str(out)], check=True)


def outputs() -> list:
    return [ICONSET / "AppIcon.png", ICONSET / "AppIcon-dark.png", ICONSET / "AppIcon-tinted.png", LIGHT_OUT]


def check() -> int:
    failed = 0
    for path in outputs():
        if not path.exists():
            print(f"missing: {path.relative_to(ROOT)}")
            failed = 1
            continue
        info = subprocess.run(["magick", "identify", "-format", "%w %h %[channels] %[opaque]", str(path)],
                              capture_output=True, text=True, check=True).stdout.split()
        width, height, channels, opaque = info[0], info[1], info[2], info[-1]
        ok = (width, height) == ("1024", "1024") and not channels.lower().endswith("a") and opaque.lower() == "true"
        print(f"{'ok ' if ok else 'BAD'} {path.relative_to(ROOT)}: {width}x{height}, channels {channels}, opaque {opaque}")
        failed |= 0 if ok else 1
    return failed


def main() -> int:
    if "--check" in sys.argv:
        return check()
    dark = palette("dark")
    render(dark, ICONSET / "AppIcon.png")
    render(dark, ICONSET / "AppIcon-dark.png")
    render(TINTED, ICONSET / "AppIcon-tinted.png", grey=True)
    render(palette("light"), LIGHT_OUT)
    return check()


if __name__ == "__main__":
    sys.exit(main())
