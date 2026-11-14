# Yandex Music provider — full transfer design

**Date:** 2026-11-14  
**Status:** Approved for planning  
**Product:** SoundShift (`qere.music`)  
**Approach:** A — thin first-party HTTP client + polished OAuth (no third-party YM SDK)

## Goal

Ship **full library migration** with Yandex Music as a first-class peer of Spotify and Apple Music: Connect → Sync → Preview → Rematch → write playlist (+ optional likes) → Report. YM works as **source and destination**.

No partner program. No “coming soon” / unofficial-API scare copy in the product UI — Connect and Transfer treat YM like the other two services.

## Non-goals

- Official Yandex partner SDK or App Store partnership narrative
- YM Demo / mock library (LIVE or disconnected only)
- Changing MatchingEngine / SkipPolicy / EmptyTransferPlanner algorithms
- Overwrite in-place playlists, nightly sync, or public App Store policy work in this phase

## Architecture

```
YandexAuthManager          → Device / web OAuth → Keychain (token + uid)
YandexMusicAPIClient       → HTTPS api.music.yandex.net, Authorization: OAuth <token>
YandexMusicProvider        → MusicProviderProtocol, isLiveSession from valid token
ServicesCoordinator        → wires provider; availableConnectors includes YM when enabled
UI (ServicesHub / Transfer)→ same LIVE badge, marble cards, MigrationPhase HUD
```

TransferManager and MatchingEngine stay unchanged except consuming `yandexId` and the enabled connector list.

## Components

### 1. `YandexAuthManager`

- Polished Connect sheet (brand banner, same visual language as Spotify setup)
- OAuth Device Flow and/or `ASWebAuthenticationSession` / WKWebView session sufficient to obtain a music access token + account `uid`
- Persist token + uid in Keychain; clear on revoke
- Surface account display name after auth

### 2. `YandexMusicAPIClient`

Authenticated JSON client with:

| Area | Capabilities |
|------|----------------|
| Account | status / uid / display name |
| Likes | list favorites; add-multiple; remove |
| Playlists | list; fetch tracks (paginated); create; add tracks |
| Search | tracks by title + artist (limit) |

Requirements:

- Pagination for likes and playlist tracks
- 429 / Retry-After handling (parity with SpotifyWebAPIClient)
- Map responses → `UniversalTrack` / `UniversalPlaylist` with `yandexId` set
- Refuse empty playlist create when input tracks were non-empty but none resolved (parity with Spotify/Apple honesty)

### 3. `YandexMusicProvider`

- `isConnectorEnabled = true`
- `isLiveSession == isAuthenticated && tokenPresent`
- Implements full `MusicProviderProtocol`
- No demo path

### 4. UI / wiring

- Services hub: always show YM card when enabled (same DEMO/SIM/LIVE rules; YM has no Demo)
- Transfer source/destination pickers include YM
- Create playlist destinations include YM when LIVE
- Player “Open in Yandex” when `yandexId` present
- DuplicatesEngine already treats YM as a third service when enabled

## Transfer flows

Supported pairs once LIVE:

- Spotify ↔ Yandex Music
- Apple Music ↔ Yandex Music
- (existing Spotify ↔ Apple unchanged)

Shared UX:

1. Preview (dry-run) with Ready / Decide / Missing
2. Strict mode: Rematch Inbox before migrate
3. Optional playlist name → `PlaylistNameBuilder`
4. Live HUD / Bridge phases (`MigrationPhase`)
5. Report with missing list + write-drop warnings
6. Conflict Skip / Merge only (Overwrite still not shipped)

Write path on YM:

- Create new playlist with resolved track IDs
- Optional `saveTracksToLibrary` (likes) when Advanced toggle is on
- Skip existing against destination **library**, not match pool

## Error & honesty rules

- Block migrate unless both ends are LIVE (existing `requireLivePair`)
- Catalog / resolve failures become missing or hard failure — never a silent empty playlist when the user selected tracks
- Partial likes failure → `warningMessage` on report (existing pattern)
- Revoke strips `yandexId` from merged rows and drops orphans (existing coordinator pattern)

## Verification

1. **Core / unit:** JSON → `UniversalTrack` mapping; create-playlist payload; empty-resolve throws; likes count
2. **Build:** iOS Simulator + device target compiles with flag on
3. **Maestro:** YM visible on Connect; Transfer picker can show Yandex
4. **Device E2E (manual):** Connect YM → Sync → Preview → migrate Spotify→YM and YM→Spotify (Apple pair if MusicKit available)

## Rollout

1. Implement client + auth + provider behind clean modules
2. Flip `isConnectorEnabled` to `true`
3. Device QA on full pairs
4. Keep Spotify/Apple regression suite green

## Risks (engineering, not product copy)

- Private/undocumented music API may change without notice → isolate in `YandexMusicAPIClient`, fail with clear status strings
- Auth flows differ by account type → prefer Device Flow with a polished fallback web session
- Matching without ISRC on some YM tracks → rely on title/artist + Rematch Strict path

## Success criteria

- User can Connect YM, Sync library, and complete a full transfer **to** and **from** YM with the same UX quality as Spotify↔Apple
- No YM stub errors in Connect/Transfer when LIVE
- Core suite + build green; Maestro Connect/Transfer smoke green
