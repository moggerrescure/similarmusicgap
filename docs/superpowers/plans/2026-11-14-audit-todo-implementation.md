# Audit TODO Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Close audit TODOs: hide YM UX, ship in-app deep links, deepen unit tests + verify.

**Architecture:** Feature-flag gates for YM UI; pure `AppDeepLinkRouter` + `NavigationCoordinator.apply`; expand `scripts/` swiftc core suite (MatchingEngine, LibraryLocalSearch, deep links).

**Tech Stack:** SwiftUI iOS 17.6, Foundation MatchingEngine, Maestro optional.

---

### Task 1: Yandex hide
- [x] Gate ServicesHub YM card behind `isConnectorEnabled`
- [x] Remove Profile “later” YM row when disabled
- [x] Gate personal-library YM filter chip / badges
- [x] Gate YM brand badge when flag off
- [x] Onboarding: Spotify+Apple only copy

### Task 2: Deep links
- [x] Add `AppDeepLink.swift` + router
- [x] `NavigationCoordinator.apply(_:)`
- [x] Wire `SoundShiftApp.handleIncomingURL`
- [x] Unit tests for router

### Task 3: Matching / Search / Skip tests
- [x] Extend `CoreBrokenFixesTestsMain` with MatchingEngine + LibraryLocalSearch + deep links
- [x] Compile suite green (48 PASS)

### Task 4: Verify
- [x] Build + install SUCCEEDED
- [x] Core suite 48/48 PASS
- [x] Visual: `soundshift://connect` opens Connect (Spotify+Apple, no YM)
- [~] Maestro UI: flaky on iOS “Open in music?” + XCTest driver timeouts; router covered by unit tests; flows 13/14 rewritten around Home Connect / Create + Cancel
