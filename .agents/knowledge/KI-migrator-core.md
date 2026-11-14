# KI: Migrator core

## Intent
SoundShift moves libraries between Spotify / Apple Music / Yandex under LIVE sessions.

## Key types
- `MigratorChrome` — tab & sheet titles
- `TransferRematchGate` — Strict rematch blocks migrate + bridge
- `ServicesCoordinator.syncIfNeededWhileVisible` — on-screen sync only
- `TransferManager.requireLivePair` — DEMO blocked
- `YandexAuthManager.refreshAccessTokenIfPossible` — token refresh
- `NavigationCoordinator.openYandexConnect` — global Device Flow sheet

## User path
Connect LIVE → Sync (Migrations/Move/Connect) → Move dry-run → migrate → Migrations history / report / rematch
