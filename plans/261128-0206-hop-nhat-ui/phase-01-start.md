---
title: "Phase 1: Core logic and tests"
status: completed
---

# Phase 1: Core logic and tests

## Overview

Add the platform-neutral logic the new UI needs to `BlockerCore`, with tests, without changing existing behaviour.

## Files

- Create: `BlockerCore/Sources/BlockerCore/NumberInput.swift`, `BlockerCore/Sources/BlockerCore/HomeStatus.swift`
- Create: `BlockerCore/Tests/BlockerCoreTests/NumberInputTests.swift`, `BlockerCore/Tests/BlockerCoreTests/HomeStatusTests.swift`

## Implementation Steps

1. Add `NumberInput.interpret` that normalizes input, infers landline or mobile length, picks one number or a prefix, and delegates validation to `RuleFactory.preview`.
2. Add `NumberDisplay` to format E.164 patterns as Vietnamese national numbers.
3. Add `HomeStatus.resolve` that maps extension state, list readability and entry count to the hero state.
4. Write tests for 028888, a full landline, a full mobile, +84 input, too-short and too-long input, formatting and every hero state.

## Todo

- [x] Add `NumberInput.interpret` that normalizes input, infers landline or mobile length, picks one number or a prefix, and delegates validation to `RuleFactory.preview`.
- [x] Add `NumberDisplay` to format E.164 patterns as Vietnamese national numbers.
- [x] Add `HomeStatus.resolve` that maps extension state, list readability and entry count to the hero state.
- [x] Write tests for 028888, a full landline, a full mobile, +84 input, too-short and too-long input, formatting and every hero state.

## Success Criteria

`ak host gate -- swift test --package-path BlockerCore` passes, including the 22 existing tests.
