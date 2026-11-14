# Migrator IA + correctness fixes (2026-11-14)

## Goal
SoundShift presents as a **music migrator**, not a Spotify clone. Fix real broken paths.

## Product IA
| Was | Becomes |
|-----|---------|
| Create tab | **Move** |
| Your Library tab | **Migrations** |
| Liked Songs & Library sheet | **Synced Library** |
| Liked Songs shortcut | **Synced collection** |
| Local ♥ | **Saved in SoundShift** (local only) |

## Bug fixes
1. Create/Move: tapping Yandex when disconnected opens `YandexConnectSheet` (not silent `authenticate()`).
2. «Живой мост» uses the same Strict rematch gate as primary migrate.
3. Yandex: refresh access token via stored refresh_token before API use when possible.

## Verify (done)
- Core suite CORE:0 (incl. RematchGate + MigratorChrome)
- xcodebuild BUILD SUCCEEDED
- Maestro 09 Passed; Maestro 10 Passed (resilient scroll)
