#!/usr/bin/env python3
"""Generate the iOS colour assets from design/tokens.json.

Each colour token becomes ios/App/Assets.xcassets/Tokens/<token>.colorset with a light
and a dark appearance, so SwiftUI switches with the system. Android reads the same JSON.

Usage:
  python3 scripts/generate-theme-assets.py           write the assets
  python3 scripts/generate-theme-assets.py --check   fail if assets or Theme.swift drift from the tokens
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOKENS = ROOT / "design" / "tokens.json"
ASSETS = ROOT / "ios" / "App" / "Assets.xcassets" / "Tokens"
THEME = ROOT / "ios" / "App" / "Theme.swift"


def components(hex_color: str) -> dict:
    value = hex_color.lstrip("#")
    alpha = int(value[6:8], 16) / 255 if len(value) == 8 else 1.0
    return {"red": f"0x{value[0:2]}", "green": f"0x{value[2:4]}", "blue": f"0x{value[4:6]}", "alpha": f"{alpha:.3f}"}


def colorset(light: str, dark: str) -> str:
    def entry(hex_color, appearance=None):
        item = {"color": {"color-space": "srgb", "components": components(hex_color)}, "idiom": "universal"}
        if appearance:
            item["appearances"] = [{"appearance": "luminosity", "value": appearance}]
        return item

    data = {"colors": [entry(light), entry(dark, "dark")], "info": {"author": "xcode", "version": 1}}
    return json.dumps(data, indent=2) + "\n"


def expected() -> dict:
    color = json.loads(TOKENS.read_text())["color"]
    if color["light"].keys() != color["dark"].keys():
        sys.exit("tokens.json: light and dark must define the same tokens")
    files = {Path("Contents.json"): json.dumps({"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": True}}, indent=2) + "\n"}
    for name in color["light"]:
        files[Path(f"{name}.colorset") / "Contents.json"] = colorset(color["light"][name], color["dark"][name])
    return files


def main() -> None:
    files = expected()
    if "--check" in sys.argv:
        problems = [str(p) for p, text in files.items() if not (ASSETS / p).exists() or (ASSETS / p).read_text() != text]
        on_disk = {p.name for p in ASSETS.glob("*.colorset")}
        problems += [f"stale {n}" for n in on_disk - {p.parent.name for p in files if p.parent.name}]
        swift = set(re.findall(r'static let (\w+) = token\("(\w+)"\)', THEME.read_text()))
        names = {p.parent.name.removesuffix(".colorset") for p in files if p.parent.name}
        problems += [f"Theme.swift missing or misnamed token {n}" for n in names - {a for a, b in swift if a == b}]
        problems += [f"Theme.swift has unknown token {a}" for a, b in swift if b not in names]
        if problems:
            sys.exit("Theme assets are out of date:\n  " + "\n  ".join(sorted(problems)) + "\nRun: python3 scripts/generate-theme-assets.py")
        print(f"ok: {len(names)} colour tokens match design/tokens.json")
        return
    for stale in ASSETS.glob("*.colorset"):
        if Path(stale.name) / "Contents.json" not in files:
            for child in stale.iterdir():
                child.unlink()
            stale.rmdir()
    for path, text in files.items():
        (ASSETS / path).parent.mkdir(parents=True, exist_ok=True)
        (ASSETS / path).write_text(text)
    print(f"wrote {len(files) - 1} colour sets to {ASSETS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
