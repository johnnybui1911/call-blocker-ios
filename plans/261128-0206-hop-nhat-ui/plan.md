---
title: "Hợp nhất UI for the iOS app"
description: "Implement the approved Hợp nhất design (layout A, dark and light tokens, animated shield) in SwiftUI without changing blocking behaviour."
status: in-progress
priority: P1
effort: "1d"
tags: [ios, swiftui, ui]
created: 2026-11-28
---

# Hợp nhất UI for the iOS app

## Overview

The owner approved the "Hợp nhất" mockup. This plan replaces the two-tab MVP UI with one status-first home screen, one "Chặn số" sheet and one setup sheet, in dark and light, using the tokens in `plans/reports/mockups-v3/src/tokens.json`.

Source of truth: `plans/reports/mockups-v3/hop-nhat.html`, its `src/tokens.json`, and the wording table in `plans/reports/261128-0158-brainstorm-p0-ui-ux-redo.md`.

## Contract

- **Outcome:** the app shows layout A "Lá chắn" with the Hợp nhất tokens in both appearances, and a user can block a full number or a 6-digit prefix from one sheet without seeing "Quy tắc", "extension" or "E.164".
- **Constraints:** `BlockRule`, `RuleArchive`, `BlocklistBuild`, `BlocklistFile`, the Call Directory extension and App Group handling keep their behaviour and file formats. Deployment target stays iOS 16. Reduce Motion and Dynamic Type are respected. Token names match `tokens.json` so Android can mirror them.
- **Non-goals:** first-launch tutorial, app icon or name, Android, new blocking features, call statistics.
- **Acceptance criteria:** `swift test` passes in `BlockerCore` including new tests; the app builds for the Simulator; Simulator screenshots exist for home, add sheet (full number and prefix 028888), protection off and empty in dark and light; no user-facing "Quy tắc" string remains.

## Decisions

| Decision | Choice | Why |
| --- | --- | --- |
| Number type | Detected from what is typed, with an override under "Nâng cao" | The approved mockup has no type picker. Existing rules keep their stored kind and length. |
| Tokens on iOS | `design/tokens.json` is the single source; a script generates asset-catalog colour sets with light and dark variants; `Theme.swift` exposes them by token name | Asset catalogs switch appearance for free, and Android can read the same JSON. |
| Home list | SwiftUI `List` with native swipe actions | Native swipe, VoiceOver actions and Dynamic Type come for free. |
| Appearance | Follows the system; the top-bar toggle pins light or dark; the menu returns to "Theo hệ thống" | Matches the mockup's toggle. |
| Backup and restore | In a "…" menu with "Cách bật chặn cuộc gọi" | The mockup's "?" button had no place for export and import, which must stay. |
| Testable logic | Input interpretation, number formatting and home-status mapping live in `BlockerCore` | The package already has tests and no app test target exists. |
| New Swift files | Regenerate the project with XcodeGen from the unchanged `project.yml` | This is the documented workflow in the README. |

## Phases

| # | Phase | Status |
|---|-------|--------|
| 1 | [Phase 1: Core logic and tests](./phase-01-start.md) | Completed |
| 2 | [Phase 2: Theme tokens](./phase-02-theme-tokens.md) | Completed |
| 3 | [Phase 3: Screens](./phase-03-screens.md) | Completed |
| 4 | [Phase 4: Verify and PR](./phase-04-verify-and-pr.md) | In progress |

## Risks

- Another branch (`johnnybui1911/default-length-by-prefix`) may infer the default length too. It has no commits yet; whoever merges second resolves the overlap.
- Call Directory does not run in the Simulator, so real blocking cannot be verified there. Screenshots use a debug-only demo state.
- iOS 26 Liquid Glass on system chrome is left to the system; no custom glass is added.

## Success Criteria

- [x] `swift test` in `BlockerCore` passes with the new tests.
- [x] The app builds for the iOS Simulator.
- [x] Screenshots captured for every required state in dark and light.
- [x] No user-facing "Quy tắc" wording remains in `ios/`.
- [ ] Pull request opened and reviewed with `/ak-review-pr`.

<!-- slug: hop-nhat-ui -->
