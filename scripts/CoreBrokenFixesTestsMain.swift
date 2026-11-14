import Foundation

@main
struct CoreBrokenFixesTestsMain {
    static func main() {
        var failures = 0
        
        func expect(_ cond: Bool, _ msg: String) {
            if !cond {
                print("FAIL: \(msg)")
                failures += 1
            } else {
                print("PASS: \(msg)")
            }
        }
        
        // --- TransferPresetResolver ---
        let likedA = UniversalTrack(title: "A", artists: ["X"], durationMs: 1000, spotifyId: "s1")
        let likedB = UniversalTrack(title: "B", artists: ["Y"], durationMs: 2000, spotifyId: "s2")
        var old = UniversalTrack(title: "Old", artists: ["Z"], durationMs: 3000, spotifyId: "s3")
        old.addedAt = Calendar.current.date(byAdding: .day, value: -60, to: Date()) ?? Date.distantPast
        
        let plTrack = UniversalTrack(title: "Pl", artists: ["P"], durationMs: 4000, spotifyId: "s4")
        let playlist = UniversalPlaylist(
            providerPlaylistId: "pl1",
            providerType: .spotify,
            title: "Mix",
            trackCount: 1,
            tracks: [plTrack]
        )
        
        let fav = TransferPresetResolver.resolve(
            preset: .favorites,
            likedTracks: [likedA, likedB, old],
            playlists: [playlist]
        )
        expect(fav.trackIds == Set([likedA.id, likedB.id, old.id]), "favorites selects liked only")
        expect(fav.playlistIds.isEmpty, "favorites excludes playlists")
        expect(fav.transferFavorites, "favorites sets transferFavorites")
        expect(!fav.trackIds.contains(plTrack.id), "favorites does not include playlist-only track")
        
        let full = TransferPresetResolver.resolve(
            preset: .full,
            likedTracks: [likedA, likedB],
            playlists: [playlist]
        )
        expect(full.trackIds.contains(likedA.id) && full.trackIds.contains(plTrack.id), "full includes liked + playlist tracks")
        expect(full.playlistIds == Set([playlist.id]), "full selects playlist ids")
        expect(full.trackIds.count == 3, "full dedupes by track id count = 3")
        
        let fullOrdered = TransferPresetResolver.tracks(
            preset: .full,
            likedTracks: [likedA, likedB],
            playlists: [playlist]
        )
        expect(fullOrdered.count == 3, "tracks() returns 3 for full vault")
        expect(fullOrdered.map(\.id).contains(plTrack.id), "tracks() includes playlist track")
        
        let favOrdered = TransferPresetResolver.tracks(
            preset: .favorites,
            likedTracks: [likedA, likedB],
            playlists: [playlist]
        )
        expect(favOrdered.count == 2, "tracks() favorites excludes playlist-only")
        
        let delta = TransferPresetResolver.resolve(
            preset: .delta,
            likedTracks: [likedA, old],
            playlists: [playlist],
            now: Date()
        )
        expect(delta.trackIds == Set([likedA.id]), "delta keeps only recent liked")
        expect(delta.playlistIds.isEmpty, "delta excludes playlists")
        expect(!delta.transferFavorites, "delta clears transferFavorites flag")
        
        // --- HomeFeedFilterLogic ---
        expect(HomeFeedFilterLogic.showsMusicContent(.all), "All shows music")
        expect(HomeFeedFilterLogic.showsMusicContent(.music), "Music shows music")
        expect(!HomeFeedFilterLogic.showsMusicContent(.podcasts), "Podcasts hides music shelves")
        expect(HomeFeedFilterLogic.showsPodcastsEmptyState(.podcasts), "Podcasts shows empty state")
        expect(!HomeFeedFilterLogic.showsPodcastsEmptyState(.music), "Music hides podcasts empty")
        
        // --- SkipPolicy (match pool ≠ destination library) ---
        let source = UniversalTrack(isrc: "USRC17607839", title: "Song", artists: ["A"], durationMs: 200000, spotifyId: "src1")
        let matched = UniversalTrack(isrc: "USRC17607839", title: "Song", artists: ["A"], durationMs: 200000, appleMusicId: "am1")
        let emptyLib: [UniversalTrack] = []
        let matchPool = [matched] // catalog/library hit always includes matched
        expect(
            !SkipPolicy.isAlreadyInLibrary(matched: matched, destinationLibrary: emptyLib, source: source),
            "Skip: catalog-only hit is NOT already-in-library"
        )
        expect(
            SkipPolicy.isAlreadyInLibrary(matched: matched, destinationLibrary: matchPool, source: source),
            "Skip: same track in destination library IS already-in-library"
        )
        
        // --- ArtistMatchText ---
        expect(
            ArtistMatchText.joined(["Travis Scott", "Teezo Touchdown"]) == "Travis Scott Teezo Touchdown",
            "ArtistMatchText joins all artists"
        )
        
        // --- HomeCassetteBuilder ---
        let emptyCassettes = HomeCassetteBuilder.build(playlists: [], tracks: [])
        expect(emptyCassettes.allSatisfy(\.isShowcase), "empty library → showcase fixtures")
        expect(
            HomeCassetteBuilder.sectionTitle(for: emptyCassettes).contains("SHOWCASE"),
            "empty library section title keeps SHOWCASE"
        )
        
        let plTracks = [
            UniversalTrack(title: "T1", artists: ["A"], durationMs: 180_000, spotifyId: "c1"),
            UniversalTrack(title: "T2", artists: ["B"], durationMs: 200_000, spotifyId: "c2")
        ]
        let libPL = UniversalPlaylist(
            providerPlaylistId: "p1",
            providerType: .spotify,
            title: "Night Drive",
            trackCount: 2,
            tracks: plTracks
        )
        let libCassettes = HomeCassetteBuilder.build(playlists: [libPL], tracks: plTracks)
        expect(!libCassettes.isEmpty && libCassettes.allSatisfy { !$0.isShowcase }, "library playlists → non-showcase")
        expect(
            HomeCassetteBuilder.sectionTitle(for: libCassettes).contains("LIBRARY"),
            "library section title says FROM LIBRARY"
        )
        
        // --- MatchingEngine ---
        let engine = MatchingEngine(thresholds: .strict)
        let srcISRC = UniversalTrack(isrc: "USRC17607839", title: "Blinding Lights", artists: ["The Weeknd"], durationMs: 200_000, spotifyId: "sp_bl")
        let candISRC = UniversalTrack(isrc: "USRC17607839", title: "Different Title", artists: ["Other"], durationMs: 199_000, appleMusicId: "am_bl")
        let isrcHit = engine.match(source: srcISRC, candidates: [candISRC])
        expect(isrcHit.confidence == .exactISRC, "MatchingEngine: identical ISRC → exactISRC")
        expect(isrcHit.matchedTrack?.appleMusicId == "am_bl", "MatchingEngine: ISRC picks destination id")
        
        let srcFuzzy = UniversalTrack(title: "Blinding Lights (Remastered)", artists: ["The Weeknd"], durationMs: 200_000, spotifyId: "sp_f")
        let candFuzzy = UniversalTrack(title: "Blinding Lights", artists: ["The Weeknd"], durationMs: 201_000, appleMusicId: "am_f")
        let fuzzyHit = engine.match(source: srcFuzzy, candidates: [candFuzzy])
        switch fuzzyHit.confidence {
        case .highConfidence, .exactISRC:
            expect(true, "MatchingEngine: remastered title → strong match")
        case .alternate:
            expect(true, "MatchingEngine: remastered title → alternate (acceptable)")
        case .missing:
            expect(false, "MatchingEngine: remastered title should not be missing")
        }
        
        let missingHit = engine.match(
            source: UniversalTrack(title: "ZZZ Unrelated", artists: ["Nobody"], durationMs: 120_000, spotifyId: "sp_z"),
            candidates: [candFuzzy]
        )
        expect(missingHit.confidence == .missing, "MatchingEngine: unrelated → missing")
        
        // Prefix-block must not miss strong fuzzy when first letters differ ("The Night" vs "Night")
        let srcNight = UniversalTrack(title: "The Night", artists: ["Art"], durationMs: 200_000, spotifyId: "sp_night")
        let candNight = UniversalTrack(title: "Night", artists: ["Art"], durationMs: 201_000, appleMusicId: "am_night")
        let nightHit = engine.match(source: srcNight, candidates: [candNight])
        switch nightHit.confidence {
        case .highConfidence, .alternate, .exactISRC:
            expect(true, "MatchingEngine: The Night ↔ Night not missing")
        case .missing:
            expect(false, "MatchingEngine: The Night ↔ Night must not be missing")
        }
        expect(
            MatchingEngine.normalizeStatic("The Night") == MatchingEngine.normalizeStatic("Night"),
            "MatchingEngine: article strip makes The Night == Night"
        )
        expect(
            MatchingEngine.normalizeStatic("A Song (Remastered)") == "song",
            "MatchingEngine: remaster + article normalize"
        )
        
        // --- EmptyTransferPlanner ---
        expect(
            EmptyTransferPlanner.decide(transferableCount: 3, skippedExisting: 1) == .writePlaylist,
            "EmptyTransferPlanner: has transferable → write"
        )
        expect(
            EmptyTransferPlanner.decide(transferableCount: 0, skippedExisting: 12) == .successNothingNew(skippedExisting: 12),
            "EmptyTransferPlanner: skip-all → successNothingNew"
        )
        expect(
            EmptyTransferPlanner.decide(transferableCount: 0, skippedExisting: 0) == .failureNoMatches,
            "EmptyTransferPlanner: empty → failureNoMatches"
        )
        
        // --- PlaylistNameBuilder / MissingTracksExport / MigrationPhase ---
        expect(
            PlaylistNameBuilder.resolve(custom: "  My Move  ", source: .spotify) == "My Move",
            "PlaylistNameBuilder: custom trimmed"
        )
        expect(
            PlaylistNameBuilder.resolve(custom: "  ", source: .appleMusic) == "SoundShift · from Apple Music",
            "PlaylistNameBuilder: blank → default"
        )
        expect(MigrationPhase.matching.counterLabel == "CHECKED", "MigrationPhase: matching = CHECKED not TRANSFERRED")
        expect(MigrationPhase.writingPlaylist.eyebrow.contains("WRITING"), "MigrationPhase: writing eyebrow")
        let missText = MissingTracksExport.plainText([
            UniversalTrack(title: "A", artists: ["X"], durationMs: 1, spotifyId: "m1"),
            UniversalTrack(title: "B", artists: ["Y"], durationMs: 1, spotifyId: "m2")
        ])
        expect(missText.contains("X — A") && missText.contains("Y — B"), "MissingTracksExport: artist — title lines")
        
        // didSucceed: skip-all with skippedExisting counts as success
        let skipReport = TransferExecutionReport(
            sourceProvider: .spotify,
            destinationProvider: .appleMusic,
            totalTracks: 5,
            successfullyTransferred: 0,
            skippedExisting: 5
        )
        expect(skipReport.didSucceed, "TransferExecutionReport: skip-all didSucceed")
        expect(!skipReport.isHardFailure, "TransferExecutionReport: skip-all not hard failure")
        
        // --- MatchCandidateIndex O(1) ISRC ---
        let index = MatchCandidateIndex(candidates: [candISRC, candFuzzy])
        expect(index.byISRC["USRC17607839"]?.appleMusicId == "am_bl", "MatchCandidateIndex: ISRC map hit")
        let indexedHit = engine.match(source: srcISRC, index: index)
        expect(indexedHit.confidence == .exactISRC, "MatchingEngine: match via index → exactISRC")
        
        // --- TrackDeduper merges platform IDs ---
        let left = UniversalTrack(isrc: "USAA123", title: "Same", artists: ["A"], durationMs: 1000, spotifyId: "sp_merge")
        let right = UniversalTrack(isrc: "USAA123", title: "Same", artists: ["A"], durationMs: 1000, appleMusicId: "am_merge")
        let merged = TrackDeduper.merge([left, right])
        expect(merged.count == 1, "TrackDeduper: ISRC collapse to 1")
        expect(merged[0].spotifyId == "sp_merge" && merged[0].appleMusicId == "am_merge", "TrackDeduper: keeps both platform IDs")
        
        let bySpotify = TrackDeduper.merge([
            UniversalTrack(title: "X", artists: ["Y"], durationMs: 500, spotifyId: "sp_only"),
            UniversalTrack(title: "X remaster", artists: ["Y"], durationMs: 500, spotifyId: "sp_only", appleMusicId: "am_later")
        ])
        expect(bySpotify.count == 1 && bySpotify[0].appleMusicId == "am_later", "TrackDeduper: merge by spotifyId")
        
        // Transitive: A(sp) + B(sp+am) + C(am) → one row with both IDs
        let chain = TrackDeduper.merge([
            UniversalTrack(title: "Chain", artists: ["Z"], durationMs: 900, spotifyId: "sp_chain"),
            UniversalTrack(title: "Chain", artists: ["Z"], durationMs: 900, spotifyId: "sp_chain", appleMusicId: "am_chain"),
            UniversalTrack(title: "Chain", artists: ["Z"], durationMs: 900, appleMusicId: "am_chain")
        ])
        expect(chain.count == 1, "TrackDeduper: transitive ID chain → 1")
        expect(chain[0].spotifyId == "sp_chain" && chain[0].appleMusicId == "am_chain", "TrackDeduper: chain keeps both IDs")
        
        // --- DuplicatesEngine: cross-service only; ignore YM when flagged off ---
        let dupEngine = DuplicatesEngine.shared
        let onlySpotifyDupes = [
            UniversalTrack(isrc: "USDUP1", title: "Dup", artists: ["D"], durationMs: 1000, spotifyId: "sp_a"),
            UniversalTrack(isrc: "USDUP1", title: "Dup", artists: ["D"], durationMs: 1000, spotifyId: "sp_b")
        ]
        expect(dupEngine.findDuplicates(in: onlySpotifyDupes).isEmpty, "DuplicatesEngine: same-service only → empty")
        
        let crossService = [
            UniversalTrack(isrc: "USCROSS1", title: "Cross", artists: ["C"], durationMs: 1000, spotifyId: "sp_c"),
            UniversalTrack(isrc: "USCROSS1", title: "Cross", artists: ["C"], durationMs: 1000, appleMusicId: "am_c")
        ]
        let crossGroups = dupEngine.findDuplicates(in: crossService)
        expect(crossGroups.count == 1, "DuplicatesEngine: Spotify+Apple → 1 group")
        expect(crossGroups.first?.services.contains(.spotify) == true, "DuplicatesEngine: includes Spotify")
        expect(crossGroups.first?.services.contains(.appleMusic) == true, "DuplicatesEngine: includes Apple")
        
        let ymGhost = [
            UniversalTrack(isrc: "USYM1", title: "Ghost", artists: ["G"], durationMs: 1000, yandexId: "yd_g", spotifyId: "sp_g")
        ]
        if YandexMusicProvider.isConnectorEnabled {
            expect(
                dupEngine.findDuplicates(in: ymGhost).count == 1,
                "DuplicatesEngine: YM-on Spotify+Yandex IDs → 1 cross-dupe group"
            )
        } else {
            expect(
                dupEngine.findDuplicates(in: ymGhost).isEmpty,
                "DuplicatesEngine: YM-off single Spotify+yandexId → not cross-dupe"
            )
        }
        
        // --- ConflictPolicy honesty ---
        expect(ConflictPolicy.implementedCases == [.skip, .merge], "ConflictPolicy: picker hides Overwrite until real")
        expect(ConflictPolicy.skip.description.lowercased().contains("skip"), "ConflictPolicy: Skip copy mentions skip")
        expect(ConflictPolicy.merge.description.lowercased().contains("new playlist"), "ConflictPolicy: Merge copy says new playlist")
        
        // --- TransferRematchGate (Strict + pending rematch blocks migrate & bridge) ---
        expect(
            TransferRematchGate.blocksMigrate(pendingRematchCount: 2, isStrict: true),
            "RematchGate: strict + pending → block"
        )
        expect(
            !TransferRematchGate.blocksMigrate(pendingRematchCount: 2, isStrict: false),
            "RematchGate: balanced + pending → allow"
        )
        expect(
            !TransferRematchGate.blocksMigrate(pendingRematchCount: 0, isStrict: true),
            "RematchGate: strict + empty queue → allow"
        )
        
        // --- Migrator IA chrome ---
        expect(MigratorChrome.migrationsTabTitle == "Migrations", "MigratorChrome: Migrations tab")
        expect(MigratorChrome.moveTabTitle == "Move", "MigratorChrome: Move tab")
        expect(MigratorChrome.syncedLibraryTitle == "Synced Library", "MigratorChrome: Synced Library sheet")
        
        // --- SkipPolicy library vs match-pool ---
        let destLib = [UniversalTrack(isrc: "USLIB1", title: "In Lib", artists: ["L"], durationMs: 1000, appleMusicId: "am_lib")]
        let catalogOnly = UniversalTrack(isrc: "USCAT1", title: "Catalog", artists: ["C"], durationMs: 1000, appleMusicId: "am_cat")
        let srcLib = UniversalTrack(isrc: "USLIB1", title: "In Lib", artists: ["L"], durationMs: 1000, spotifyId: "sp_lib")
        expect(
            SkipPolicy.isAlreadyInLibrary(matched: destLib[0], destinationLibrary: destLib, source: srcLib),
            "SkipPolicy: ISRC already in destination library"
        )
        expect(
            !SkipPolicy.isAlreadyInLibrary(matched: catalogOnly, destinationLibrary: destLib, source: UniversalTrack(isrc: "USCAT1", title: "Catalog", artists: ["C"], durationMs: 1000, spotifyId: "sp_cat")),
            "SkipPolicy: catalog-only match is NOT already in library"
        )
        // Source has ISRC, library row lacks ISRC but shares Apple ID — must still Skip.
        let libNoISRC = [UniversalTrack(title: "In Lib", artists: ["L"], durationMs: 1000, appleMusicId: "am_lib")]
        let matchedNoISRC = UniversalTrack(title: "In Lib", artists: ["L"], durationMs: 1000, appleMusicId: "am_lib")
        let srcWithISRC = UniversalTrack(isrc: "USLIB1", title: "In Lib", artists: ["L"], durationMs: 1000, spotifyId: "sp_lib")
        expect(
            SkipPolicy.isAlreadyInLibrary(matched: matchedNoISRC, destinationLibrary: libNoISRC, source: srcWithISRC),
            "SkipPolicy: fall through to platform ID when library lacks ISRC"
        )
        
        // One-character titles must not crash Jaro-Winkler
        _ = engine.match(
            source: UniversalTrack(title: "X", artists: ["Y"], durationMs: 1000, spotifyId: "sp_x"),
            candidates: [UniversalTrack(title: "Z", artists: ["Y"], durationMs: 1000, appleMusicId: "am_z")]
        )
        expect(true, "MatchingEngine: 1-char titles do not crash")
        
        expect(
            MatchingEngine.normalizeStatic("A Sky") == MatchingEngine.normalizeStatic("Sky"),
            "MatchingEngine: A Sky ↔ Sky article strip"
        )
        expect(
            MatchingEngine.normalizeStatic("Theatre") == "theatre",
            "MatchingEngine: Theatre is not stripped as article"
        )
        
        // --- LibraryLocalSearch ---
        let searchTracks = [
            UniversalTrack(title: "Nightcall", artists: ["Kavinsky"], album: "OutRun", durationMs: 259_000, spotifyId: "n1"),
            UniversalTrack(title: "Resonance", artists: ["HOME"], durationMs: 212_000, spotifyId: "n2")
        ]
        let searchPLs = [
            UniversalPlaylist(providerPlaylistId: "pl", providerType: .spotify, title: "Night Drive", trackCount: 1, tracks: [searchTracks[0]])
        ]
        let night = LibraryLocalSearch.search(query: "night", tracks: searchTracks, playlists: searchPLs)
        expect(night.tracks.contains(where: { $0.title == "Nightcall" }), "LibraryLocalSearch: track title hit")
        expect(night.playlists.contains(where: { $0.title == "Night Drive" }), "LibraryLocalSearch: playlist title hit")
        expect(night.artists.contains("Kavinsky") || night.tracks.contains(where: { $0.primaryArtist == "Kavinsky" }), "LibraryLocalSearch: artist surface")
        
        let emptyQ = LibraryLocalSearch.search(query: "   ", tracks: searchTracks, playlists: searchPLs)
        expect(emptyQ.isEmpty, "LibraryLocalSearch: blank query → empty")
        
        let tagHit = LibraryLocalSearch.firstTrack(matchingTag: "resonance", in: searchTracks)
        expect(tagHit?.title == "Resonance", "LibraryLocalSearch: firstTrack tag")
        
        // --- AppDeepLinkRouter ---
        expect(AppDeepLinkRouter.parse(URL(string: "https://example.com")!) == nil, "DeepLink: wrong scheme → nil")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://spotify-callback")!) == .spotifyCallback, "DeepLink: oauth callback")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://connect")!) == .connect, "DeepLink: connect")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://services")!) == .connect, "DeepLink: services alias")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://library")!) == .library, "DeepLink: library")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://move")!) == .move, "DeepLink: move")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://create")!) == .move, "DeepLink: create → move")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://transfer")!) == .move, "DeepLink: transfer → move")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://taste")!) == .taste, "DeepLink: taste")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://home")!) == .home, "DeepLink: home")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://search")!) == .search(query: nil), "DeepLink: search bare")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://search?q=pop")!) == .search(query: "pop"), "DeepLink: search?q=")
        expect(AppDeepLinkRouter.parse(URL(string: "soundshift://nope")!) == nil, "DeepLink: unknown host → nil")
        
        // --- availableConnectors includes YM when flagged on ---
        expect(
            MusicProviderType.availableConnectors.contains(.yandexMusic) == YandexMusicProvider.isConnectorEnabled,
            "YM availableConnectors matches isConnectorEnabled"
        )
        
        // --- YandexMusicMapper ---
        let ymTrackJSON = """
        {"id":"7019818","title":"Ничего на земле","durationMs":240000,"artists":[{"name":"Oxxxymiron"}],"albums":[{"title":"Горгород","year":2015}]}
        """.data(using: .utf8)!
        let ymTrack = try! JSONDecoder().decode(YandexTrack.self, from: ymTrackJSON)
        let mappedYM = YandexMusicMapper.mapTrack(ymTrack)
        expect(mappedYM?.yandexId == "7019818", "YandexMusicMapper: yandexId")
        expect(mappedYM?.title == "Ничего на земле", "YandexMusicMapper: title")
        expect(mappedYM?.primaryArtist == "Oxxxymiron", "YandexMusicMapper: artist")
        expect(
            YandexMusicMapper.shouldRefuseEmptyWrite(requestedCount: 5, resolvedCount: 0),
            "YandexMusicMapper: refuse empty write"
        )
        expect(
            !YandexMusicMapper.shouldRefuseEmptyWrite(requestedCount: 0, resolvedCount: 0),
            "YandexMusicMapper: allow intentionally empty create"
        )
        expect(
            YandexMusicMapper.splitPlaylistId("541320800:1003")?.kind == 1003,
            "YandexMusicMapper: split playlist id"
        )
        expect(YandexMusicProvider.isConnectorEnabled, "YM connector enabled")
        
        if failures > 0 {
            print("\n\(failures) failure(s)")
            exit(1)
        }
        print("\nAll core broken-fix tests passed")
    }
}
