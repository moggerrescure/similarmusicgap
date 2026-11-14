# Full project audit pass (2026-11-14)

## Fixed this pass
- LIVE badge driven by `isLiveSession` (SETUP/DEMO/SIM honesty)
- Create playlist destinations require LIVE
- Revoke strips provider IDs on merged rows
- Preview duration honesty after crossfade
- Bridge dismiss locked while migrating
- Blocked errors show real reason (not “Blocked”)
- Apple/Spotify refuse empty playlist when input tracks failed resolve
- TransferManager accounts write drops → missing + warning
- HUD phase no longer flashes FAILED from stale errors
- Liked Songs toggle honesty; Favorites preset no longer forces likes write
- Strict rematch gate before migrate
- Delta preset renamed Recent likes (30d)
- Player deep-link chips follow queue head

## Deferred (known, not ship-blockers for sim)
- Live E2E on device / Client ID / TestFlight Team
- Overwrite in-place playlist replace (intentionally hidden)
- Cache CandidatePool between dry-run and live (perf)
- Playlist hydrate failure surfacing when `tracks == []` but API trackCount > 0

## Closed later same day
- Nightly / background sync removed (foreground only)
- Yandex connector enabled + Device Flow + refresh
- Migrator IA (Migrations / Move / Synced Library)
- Rematch gate on Живой мост
- YM connect from Move via `openYandexConnect`
- No remote likes; migrate = new playlist only
- See ADR `docs/adr/0001-soundshift-as-migrator.md` + `AGENTS.md`

## Verify
- Core suite CORE:0
- xcodebuild BUILD SUCCEEDED
- Maestro smoke when driver healthy
