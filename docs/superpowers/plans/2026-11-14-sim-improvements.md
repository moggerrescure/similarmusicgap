# Simulator-safe improvements plan

**Goal:** Ship code-quality fixes 1–14 without device E2E.

**Architecture:** MatchingEngine index + yields; TransferManager rematch/conflict honesty; shared TrackDeduper; Spotify retry; packaging + UX copy polish.

### Tasks
1. [x] MatchingEngine ISRC map + optional progress yield API used by TransferManager
2. [x] Keep rematchQueue after live; RematchInbox empty copy honesty
3. [x] ConflictPolicy: Skip filters already-in-library; Merge/Overwrite labeled honestly (same write until in-place exists)
4. [x] TrackDeduper merges platform IDs
5. [x] SpotifyWebAPIClient 429 retry
6. [x] App Icon + PrivacyInfo + gitignore reports
7. [x] Search/Taste/M3U/Apple revoke polish
8. [x] Core tests + build (58 PASS, BUILD SUCCEEDED 2026-11-14)
