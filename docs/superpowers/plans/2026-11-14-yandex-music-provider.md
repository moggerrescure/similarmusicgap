# Yandex Music Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or implement task-by-task with TDD. Steps use checkbox (`- [ ]`) syntax.

**Goal:** First-class Yandex Music Connect + full transfer (source & destination) via thin HTTP client + Device Flow OAuth.

**Architecture:** `YandexAuthManager` (device code UI) → Keychain → `YandexMusicAPIClient` → `YandexMusicProvider` (`MusicProviderProtocol`). Flip `isConnectorEnabled`. No UI disclaimer.

**Tech Stack:** SwiftUI iOS 17.6, Foundation URLSession, Keychain, existing TransferManager/MatchingEngine.

## Global Constraints

- No third-party YM SPM SDK
- LIVE-only (no Demo)
- Product UI treats YM equal to Spotify/Apple
- Refuse empty playlist when resolve yields 0 of N tracks
- Core suite + xcodebuild must stay green

## File map

| File | Role |
|------|------|
| `App/Core/YandexMusicMapper.swift` | Pure JSON → UniversalTrack/Playlist |
| `App/Services/YandexMusicAPIClient.swift` | HTTP + 429 retry |
| `App/Services/YandexAuthManager.swift` | Device Flow + Keychain |
| `App/Services/YandexMusicProvider.swift` | Protocol impl, flag on |
| `App/Views/Services/YandexConnectSheet.swift` | Polished Connect UI |
| `App/Views/Services/ServicesHubView.swift` | Wire Connect sheet |
| `scripts/CoreBrokenFixesTestsMain.swift` | Mapper + empty-create tests |

### Task 1: Mapper + failing tests

- [x] Add mapper tests (track / likes page / refuse empty)
- [x] Implement `YandexMusicMapper`
- [x] CORE green for new tests

### Task 2: API client

- [x] `YandexMusicAPIClient` account/likes/playlists/search/create/add/likes-write
- [x] 429 retry parity

### Task 3: Auth + Provider

- [x] Device Flow auth manager
- [x] Full `YandexMusicProvider`, `isConnectorEnabled = true`

### Task 4: UI + hub

- [x] `YandexConnectSheet` (code + open + poll)
- [x] Hub / Transfer already pick up `availableConnectors`

### Task 5: Verify

- [x] Core suite + xcodebuild (`CORE:0`, `BUILD SUCCEEDED`)
- [ ] Device: Connect YM → Sync → migrate (manual)
