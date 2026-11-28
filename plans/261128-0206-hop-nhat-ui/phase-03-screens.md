---
title: "Phase 3: Screens"
status: completed
---

# Phase 3: Screens

## Overview

Replace the tab UI with the home screen, the "Chặn số" sheet and the setup sheet, using the wording table.

## Files

- Create: `ios/App/HomeView.swift`, `ios/App/ShieldView.swift`, `ios/App/BlockNumberSheet.swift`, `ios/App/SetupSheet.swift`, `ios/App/Feedback.swift`
- Modify: `ios/App/ChanCuocGoiApp.swift`, `ios/App/Vietnamese.swift`, `ios/App/RuleStore.swift`, `ios/App/ExtensionStatus.swift`
- Delete: `ios/App/RulesView.swift`, `ios/App/RuleEditorView.swift`, `ios/App/GuideView.swift`
- Regenerate: `ChanCuocGoi.xcodeproj`

## Implementation Steps

1. Build the animated shield with pulse rings, a stamp on block and a Reduce Motion fallback.
2. Build the home screen: hero, list with swipe to unblock and edit, docked button, toast, menu and appearance toggle.
3. Build the sheet with auto-detected type, live result, note, paste and advanced overrides.
4. Build the setup sheet with the four steps, success state and technical details.
5. Reword store and error messages, remove the reload button and keep a retry on failure.
6. Add a debug-only demo state for Simulator screenshots.
7. Regenerate the Xcode project.

## Todo

- [x] Build the animated shield with pulse rings, a stamp on block and a Reduce Motion fallback.
- [x] Build the home screen: hero, list with swipe to unblock and edit, docked button, toast, menu and appearance toggle.
- [x] Build the sheet with auto-detected type, live result, note, paste and advanced overrides.
- [x] Build the setup sheet with the four steps, success state and technical details.
- [x] Reword store and error messages, remove the reload button and keep a retry on failure.
- [x] Add a debug-only demo state for Simulator screenshots.
- [x] Regenerate the Xcode project.

## Success Criteria

The app builds for the Simulator and no user-facing "Quy tắc", "extension", "CallKit" or "E.164" string remains outside technical details.
