# SoundShift (qere.music) — agent notes

## Product
Music **migrator**, not a Spotify clone. Canonical IA: Home · Search · Migrations · Move. Connect & Taste are sheets.

## Truth table
| Topic | Rule |
|-------|------|
| Tabs | `MigratorChrome` — Migrations / Move |
| Synced collection | Service library after Sync |
| ♥ | Local SoundShift bookmarks only |
| Migrate write | New playlist only; no Liked Songs |
| Conflict | Skip + Merge; Overwrite ≡ Merge (hidden) |
| Sync | `syncIfNeededWhileVisible` on screen; no background |
| LIVE | `isLiveSession` required for sync ingest + migrate |
| Yandex | Device Flow sheet; `openYandexConnect()`; refresh when possible |
| Rematch Strict | Blocks primary migrate **and** Живой мост (`TransferRematchGate`) |

## Layout
- App: `music/music/App/`
- Core suite: `scripts/CoreBrokenFixesTestsMain.swift` (swiftc recipe in plans)
- Maestro: `maestro/flows/` + `maestro/scripts/run_suite.sh`
- Plans/specs: `docs/superpowers/`
- ADRs: `docs/adr/`

## Verify before “done”
1. Core suite → `CORE:0`
2. `xcodebuild` → `BUILD SUCCEEDED`
3. Maestro smoke (09/10 + suite when driver healthy)

## Do not
- Claim live OAuth/migrate works without device evidence
- Re-enable remote like sync or nightly background sync without an ADR
- Invent screenshots / Client IDs / TestFlight results
