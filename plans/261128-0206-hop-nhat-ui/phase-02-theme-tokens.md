---
title: "Phase 2: Theme tokens"
status: completed
---

# Phase 2: Theme tokens

## Overview

Bring the Hợp nhất tokens into the app as an asset-catalog theme layer with one source file.

## Files

- Create: `design/tokens.json`, `scripts/generate-theme-assets.py`
- Create: `ios/App/Assets.xcassets/Tokens/*.colorset` (generated)
- Modify: `ios/App/Theme.swift`, `ios/App/Assets.xcassets/AccentColor.colorset/Contents.json`

## Implementation Steps

1. Copy the approved tokens to `design/tokens.json`.
2. Write the generator with a `--check` mode that fails when assets drift from the tokens.
3. Generate one colour set per token with light and dark appearances.
4. Rewrite `Theme.swift` to expose colours by token name plus radii, sizes, motion and rounded fonts.

## Todo

- [x] Copy the approved tokens to `design/tokens.json`.
- [x] Write the generator with a `--check` mode that fails when assets drift from the tokens.
- [x] Generate one colour set per token with light and dark appearances.
- [x] Rewrite `Theme.swift` to expose colours by token name plus radii, sizes, motion and rounded fonts.

## Success Criteria

`python3 scripts/generate-theme-assets.py --check` exits 0 and every token in `design/tokens.json` has a colour set.
