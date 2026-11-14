# Audit TODO Design — Yandex hide · Deep links · Unit tests

**Date:** 2026-11-14  
**Scope:** Punchlist TODO items (A): Yandex UX hide, deep-link routes, MatchingEngine / Transfer / LibraryLocalSearch tests.  
**Out of scope:** Physical-device live migrate E2E; shipping a real Yandex API.

## Goals

1. **Yandex:** When `YandexMusicProvider.isConnectorEnabled == false`, no user-facing YM card, filter, badge, or “coming later” chrome. Enum/data fields may remain for future.
2. **Deep links:** `soundshift://` hosts route into app navigation (Connect, Library, Move/Create, Search, Taste, Home). OAuth callback stays a no-op for ASWebAuth.
3. **Tests:** Deterministic unit coverage for MatchingEngine, LibraryLocalSearch, SkipPolicy/gates helpers, and deep-link parsing — runnable without Simulator UI.

## Design

### Yandex hide
- Gate **all** YM UI with `isConnectorEnabled` (ServicesHub card, Profile row, personal-library provider filter, player deep-link chips already gated).
- Soften onboarding copy to Spotify + Apple only (no YM tease).
- Keep `MusicProviderType.yandexMusic` + CSV columns for schema stability.

### Deep links
- Pure `AppDeepLinkRouter.parse(URL) -> AppDeepLink?` (testable, no UIKit).
- Destinations: `home`, `search(query?)`, `library`, `connect`, `move`/`create`/`transfer`, `taste`; ignore `spotify-callback`.
- `NavigationCoordinator.apply(_ link)` performs tab/sheet changes on MainActor.
- `SoundShiftApp.handleIncomingURL` parses + applies.

### Tests
- Expand `scripts/CoreBrokenFixesTestsMain.swift` (+ companion sources) into a fuller core suite: MatchingEngine ISRC/high/alternate/missing, LibraryLocalSearch, AppDeepLinkRouter.
- Keep swiftc + run path (no XCTest target yet — same CI-friendly pattern).
- Add Maestro flow that opens `soundshift://connect` after launch (optional smoke).

## Success criteria
- Build green; core suite all PASS; Maestro deep-link + existing honesty flows green where applicable.
- Grep UI for visible YM when flag false → only gated / data-model hits.
