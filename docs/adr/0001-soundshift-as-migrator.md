# ADR-0001: SoundShift is a music migrator

## Status
Accepted

## Date
2026-11-14

## Context
The UI was modeled on Spotify’s four-tab shell (Home / Search / Library / Create). That IA made SoundShift feel like a streaming client while the real product job is **LIVE library migration** between Spotify, Apple Music, and Yandex Music.

## Decision
1. **Chrome:** tabs are Home / Search / **Migrations** / **Move** (`MigratorChrome`).
2. **Synced Library** sheet holds service tracks; local ♥ = **Saved in SoundShift** only (no remote like/unlike).
3. **Writes:** migrate creates a **new playlist** only; Skip / Merge; Overwrite hidden until in-place replace exists.
4. **Sync:** foreground on Migrations / Move / Connect screens only — no nightly / BGTask.
5. **LIVE gate:** Demo / SIM cannot sync ingest or migrate.
6. **Yandex:** Device Flow via dedicated sheet; refresh_token used when present; Move/Connect open the same sheet.

## Consequences
- Home may still show SHOWCASE fixtures when empty — labeled as non-library.
- Apple sync = full Music library, not only Loved (documented in Connect hint).
- Live OAuth / full transfer E2E still requires a physical device + Client IDs.
