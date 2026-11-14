import Foundation
import Combine

/// Core Migration Orchestrator — honest dry-run matching + live destination write.
@MainActor
public final class TransferManager: ObservableObject {
    public static let shared = TransferManager()
    
    private let matchingEngine = MatchingEngine()
    private let servicesCoordinator = ServicesCoordinator.shared
    
    @Published public var isMigrating: Bool = false
    @Published public var progress: Double = 0.0
    @Published public var currentTrackTitle: String = ""
    @Published public var currentTrackArtist: String = ""
    @Published public var processedCount: Int = 0
    @Published public var totalToProcess: Int = 0
    @Published public var statusMessage: String = ""
    
    @Published public var lastDryRun: DryRunSummary?
    @Published public var rematchQueue: [MatchResult] = []
    @Published public var lastMatchResults: [MatchResult] = []
    /// Source track IDs the user accepted in Rematch Inbox (carry into live migration).
    @Published public private(set) var acceptedRematchIds: Set<UUID> = []
    /// Source track IDs the user skipped in Rematch Inbox.
    @Published public private(set) var skippedRematchIds: Set<UUID> = []
    
    @Published public var history: [TransferExecutionReport] = []
    @Published public var lastReport: TransferExecutionReport?
    @Published public var lastErrorMessage: String?
    
    /// When true, unresolved alternates auto-transfer; when false, only accepted rematches transfer.
    public var autoAcceptAlternates: Bool = false
    
    private init() {
        self.history = TransferHistoryStore.load()
    }
    
    public func applyMatchingSensitivity(_ sensitivity: MatchingSensitivity) {
        switch sensitivity {
        case .strict:
            matchingEngine.thresholds = .strict
            autoAcceptAlternates = false
        case .flexible:
            matchingEngine.thresholds = .flexible
            autoAcceptAlternates = true
        }
    }
    
    // MARK: - Source track collection
    
    public func collectSourceTracks(
        sourceType: MusicProviderType,
        scope: TransferScope
    ) async throws -> [UniversalTrack] {
        let sourceProvider = servicesCoordinator.provider(for: sourceType)
        
        // Fast path: archive selection already points at synced rows with stable IDs
        if let selectedIds = scope.selectedTrackIds, !selectedIds.isEmpty, scope.selectedPlaylistIds.isEmpty {
            let cached = servicesCoordinator.allTracks.filter {
                selectedIds.contains($0.id) && Self.trackBelongs(to: sourceType, track: $0)
            }
            if !cached.isEmpty {
                return Self.deduplicate(cached)
            }
        }
        
        var sourceTracks: [UniversalTrack] = []
        
        if scope.transferFavorites {
            let favs = try await sourceProvider.fetchFavorites()
            sourceTracks.append(contentsOf: favs)
        }
        
        if !scope.selectedPlaylistIds.isEmpty {
            // Prefer hydrated coordinator playlists; otherwise fetch tracks live
            let cached = servicesCoordinator.allPlaylists.filter {
                $0.providerType == sourceType && scope.selectedPlaylistIds.contains($0.id)
            }
            
            for playlist in cached {
                if !playlist.tracks.isEmpty {
                    sourceTracks.append(contentsOf: playlist.tracks)
                } else {
                    let tracks = try await sourceProvider.fetchPlaylistTracks(providerPlaylistId: playlist.providerPlaylistId)
                    sourceTracks.append(contentsOf: tracks)
                }
            }
            
            // IDs that weren't in coordinator cache (fresh fetch of playlist list)
            let cachedIds = Set(cached.map(\.id))
            let missingIds = scope.selectedPlaylistIds.subtracting(cachedIds)
            if !missingIds.isEmpty {
                let remotePlaylists = try await sourceProvider.fetchPlaylists()
                for pl in remotePlaylists where missingIds.contains(pl.id) {
                    let tracks = try await sourceProvider.fetchPlaylistTracks(providerPlaylistId: pl.providerPlaylistId)
                    sourceTracks.append(contentsOf: tracks)
                }
            }
        }
        
        if let selectedIds = scope.selectedTrackIds {
            sourceTracks = sourceTracks.filter { selectedIds.contains($0.id) }
        }
        
        return Self.deduplicate(sourceTracks)
    }
    
    /// Destination favorites + playlists only (no catalog search hits).
    /// Used by Skip policy — must NOT include match-pool catalog extras.
    public struct CandidatePool: Sendable {
        public let destinationLibrary: [UniversalTrack]
        public let matchPool: [UniversalTrack]
    }
    
    // MARK: - Candidate pool (destination library + catalog search for misses)
    
    public func buildCandidatePool(
        destinationType: MusicProviderType,
        sourceTracks: [UniversalTrack]
    ) async throws -> CandidatePool {
        let destinationProvider = servicesCoordinator.provider(for: destinationType)
        
        var library = try await destinationProvider.fetchFavorites()
        
        // Also fold in already-hydrated destination playlists from snapshot
        for pl in servicesCoordinator.allPlaylists where pl.providerType == destinationType {
            library.append(contentsOf: pl.tracks)
        }
        
        library = Self.deduplicate(library)
        let libraryIndex = MatchCandidateIndex(candidates: library)
        
        // For tracks that don't match the local library, pull catalog candidates
        var catalogExtras: [UniversalTrack] = []
        var catalogSearchFailures = 0
        for (index, track) in sourceTracks.enumerated() {
            if index % 20 == 0 {
                await Task.yield()
                statusMessage = "Searching catalog \(index + 1)/\(sourceTracks.count)…"
            }
            let local = matchingEngine.match(source: track, index: libraryIndex)
            switch local.confidence {
            case .exactISRC, .highConfidence:
                continue
            case .alternate, .missing:
                do {
                    let hits = try await destinationProvider.searchCatalog(
                        title: track.title,
                        artist: track.primaryArtist,
                        limit: 5
                    )
                    catalogExtras.append(contentsOf: hits)
                } catch {
                    catalogSearchFailures += 1
                }
            }
        }
        
        if catalogSearchFailures > 0 {
            statusMessage = "Catalog search failed for \(catalogSearchFailures) track\(catalogSearchFailures == 1 ? "" : "s") — matching library only"
        }
        
        let matchPool = Self.deduplicate(library + catalogExtras)
        return CandidatePool(destinationLibrary: library, matchPool: matchPool)
    }
    
    // MARK: - Live session gate (blocks Demo Mode fake transfers)
    
    private func requireLivePair(sourceType: MusicProviderType, destinationType: MusicProviderType) throws {
        let source = servicesCoordinator.provider(for: sourceType)
        let destination = servicesCoordinator.provider(for: destinationType)
        
        if sourceType == .spotify && !SpotifyConfig.isConfigured {
            throw NSError(
                domain: "TransferManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Add your Spotify Client ID in Connect → Spotify setup before transferring."]
            )
        }
        if destinationType == .spotify && !SpotifyConfig.isConfigured {
            throw NSError(
                domain: "TransferManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Add your Spotify Client ID in Connect → Spotify setup before transferring."]
            )
        }
        guard source.isAuthenticated, destination.isAuthenticated else {
            throw NSError(
                domain: "TransferManager",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Connect both source and destination services (live accounts), then Sync."]
            )
        }
        guard source.isLiveSession else {
            throw NSError(
                domain: "TransferManager",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "\(sourceType.displayName) is in Demo Mode. Disconnect and reconnect with a real account — Demo cannot migrate."]
            )
        }
        guard destination.isLiveSession else {
            throw NSError(
                domain: "TransferManager",
                code: 403,
                userInfo: [NSLocalizedDescriptionKey: "\(destinationType.displayName) is not a live session. Reconnect on a device with library access (Simulator Apple Music is often empty)."]
            )
        }
    }
    
    // MARK: - Step 1: Honest Dry-Run
    
    public func executeDryRun(
        sourceType: MusicProviderType,
        destinationType: MusicProviderType,
        scope: TransferScope
    ) async -> DryRunSummary {
        lastErrorMessage = nil
        statusMessage = "Collecting source tracks…"
        
        do {
            try requireLivePair(sourceType: sourceType, destinationType: destinationType)
            let uniqueTracks = try await collectSourceTracks(sourceType: sourceType, scope: scope)
            statusMessage = "Building destination match pool…"
            let pool = try await buildCandidatePool(
                destinationType: destinationType,
                sourceTracks: uniqueTracks
            )
            
            var exactCount = 0
            var alternateCount = 0
            var missingCount = 0
            var pendingRematches: [MatchResult] = []
            var results: [MatchResult] = []
            let matchIndex = MatchCandidateIndex(candidates: pool.matchPool)
            
            for (index, track) in uniqueTracks.enumerated() {
                if index % 20 == 0 {
                    await Task.yield()
                    statusMessage = "Matching \(index + 1)/\(uniqueTracks.count)…"
                }
                let result = matchingEngine.match(source: track, index: matchIndex)
                results.append(result)
                switch result.confidence {
                case .exactISRC, .highConfidence:
                    exactCount += 1
                case .alternate:
                    alternateCount += 1
                    pendingRematches.append(result)
                case .missing:
                    missingCount += 1
                }
            }
            
            let summary = DryRunSummary(
                totalTracks: uniqueTracks.count,
                exactMatchesCount: exactCount,
                alternateMatchesCount: alternateCount,
                missingCount: missingCount
            )
            
            self.lastDryRun = summary
            self.rematchQueue = pendingRematches
            self.lastMatchResults = results
            if pool.destinationLibrary.isEmpty && !uniqueTracks.isEmpty {
                self.statusMessage = exactCount > 0
                    ? "Destination library empty locally — \(exactCount) strong via catalog · \(alternateCount) alternate · \(missingCount) missing. Sync destination for Skip accuracy."
                    : "Destination library empty — \(missingCount) unmatched. Connect & sync destination, then re-run."
            } else {
                self.statusMessage = "Dry-run: \(exactCount) strong (ISRC/high) · \(alternateCount) alternate · \(missingCount) missing"
            }
            return summary
        } catch {
            lastErrorMessage = error.localizedDescription
            statusMessage = "Dry-run failed"
            // Do not fake a 0% “successful” preview — clear so UI shows the error path.
            lastDryRun = nil
            rematchQueue = []
            lastMatchResults = []
            return DryRunSummary(totalTracks: 0, exactMatchesCount: 0, alternateMatchesCount: 0, missingCount: 0)
        }
    }
    
    // MARK: - Step 2: Live Migration (real write)
    
    public func startMigration(
        sourceType: MusicProviderType,
        destinationType: MusicProviderType,
        scope: TransferScope,
        policy: ConflictPolicy
    ) async -> TransferExecutionReport {
        if isMigrating {
            let busy = TransferExecutionReport(
                sourceProvider: sourceType,
                destinationProvider: destinationType,
                totalTracks: totalToProcess,
                successfullyTransferred: 0,
                errorMessage: "A migration is already running — wait for it to finish."
            )
            lastErrorMessage = busy.errorMessage
            return busy
        }
        
        self.isMigrating = true
        self.progress = 0.0
        self.processedCount = 0
        self.totalToProcess = 0
        self.currentTrackTitle = ""
        self.currentTrackArtist = ""
        self.lastErrorMessage = nil
        self.statusMessage = "Preparing migration…"
        
        let startTime = Date()
        let destinationProvider = servicesCoordinator.provider(for: destinationType)
        var missingList: [UniversalTrack] = []
        var rematchSnapshot: [MatchResult] = []
        
        do {
            try requireLivePair(sourceType: sourceType, destinationType: destinationType)
            
            let sourceTracks = try await collectSourceTracks(sourceType: sourceType, scope: scope)
            self.totalToProcess = sourceTracks.count
            
            guard !sourceTracks.isEmpty else {
                throw NSError(
                    domain: "TransferManager",
                    code: 400,
                    userInfo: [NSLocalizedDescriptionKey: "No source tracks in scope. Sync the source library or select a playlist with tracks."]
                )
            }
            
            statusMessage = "Matching against destination…"
            let pool = try await buildCandidatePool(destinationType: destinationType, sourceTracks: sourceTracks)
            
            var transferable: [UniversalTrack] = []
            missingList = []
            var alternatesAccepted = 0
            var skippedExisting = 0
            var results: [MatchResult] = []
            let matchIndex = MatchCandidateIndex(candidates: pool.matchPool)
            
            for (index, track) in sourceTracks.enumerated() {
                if index % 20 == 0 {
                    await Task.yield()
                }
                self.currentTrackTitle = track.title
                self.currentTrackArtist = track.primaryArtist
                self.processedCount = index + 1
                self.progress = Double(index) / Double(max(sourceTracks.count, 1)) * 0.7
                self.statusMessage = "Matching \(index + 1)/\(sourceTracks.count)"
                
                let result = matchingEngine.match(source: track, index: matchIndex)
                results.append(result)
                
                switch result.confidence {
                case .exactISRC, .highConfidence:
                    if let matched = result.matchedTrack {
                        // Skip only if destination LIBRARY already has it — not if it merely
                        // appeared as a catalog search hit in matchPool (that was always true).
                        let alreadyThere = Self.isAlreadyInLibrary(
                            matched,
                            destinationLibrary: pool.destinationLibrary,
                            source: track
                        )
                        switch policy {
                        case .skip:
                            if alreadyThere {
                                skippedExisting += 1
                                continue
                            }
                            transferable.append(matched)
                        case .merge, .overwrite:
                            transferable.append(matched)
                        }
                    }
                case .alternate:
                    if skippedRematchIds.contains(track.id) {
                        missingList.append(track)
                        continue
                    }
                    let userAccepted = acceptedRematchIds.contains(track.id)
                    guard userAccepted || autoAcceptAlternates else {
                        // Strict mode: leave unresolved until Rematch Inbox accepts
                        missingList.append(track)
                        continue
                    }
                    if let matched = result.matchedTrack {
                        let alreadyThere = Self.isAlreadyInLibrary(
                            matched,
                            destinationLibrary: pool.destinationLibrary,
                            source: track
                        )
                        if policy == .skip && alreadyThere {
                            skippedExisting += 1
                            continue
                        }
                        transferable.append(matched)
                        alternatesAccepted += 1
                    } else {
                        missingList.append(track)
                    }
                case .missing:
                    missingList.append(track)
                }
                
                if index % 25 == 0 {
                    HapticManager.lightImpact()
                }
            }
            
            self.lastMatchResults = results
            rematchSnapshot = results.filter { result in
                guard case .alternate = result.confidence else { return false }
                if acceptedRematchIds.contains(result.sourceTrack.id) { return false }
                if skippedRematchIds.contains(result.sourceTrack.id) { return false }
                if autoAcceptAlternates { return false }
                return missingList.contains(where: { $0.id == result.sourceTrack.id })
            }
            
            // Deduplicate destination IDs before write
            transferable = Self.deduplicate(transferable)
            
            let writeDecision = EmptyTransferPlanner.decide(
                transferableCount: transferable.count,
                skippedExisting: skippedExisting
            )
            
            let durationSoFar = { Date().timeIntervalSince(startTime) }
            
            switch writeDecision {
            case .failureNoMatches:
                throw NSError(
                    domain: "TransferManager",
                    code: 422,
                    userInfo: [NSLocalizedDescriptionKey: "No matched tracks to write. Re-run dry-run, open Rematch Inbox, or sync destination library."]
                )
                
            case .successNothingNew(let skipped):
                self.progress = 1.0
                self.processedCount = sourceTracks.count
                self.statusMessage = missingList.isEmpty
                    ? "Nothing new — \(skipped) already on \(destinationType.displayName)"
                    : "Nothing new to write — \(skipped) already there, \(missingList.count) still missing"
                
                let report = TransferExecutionReport(
                    sourceProvider: sourceType,
                    destinationProvider: destinationType,
                    totalTracks: sourceTracks.count,
                    successfullyTransferred: 0,
                    skippedExisting: skipped,
                    missingTracks: missingList,
                    alternatesAccepted: alternatesAccepted,
                    durationSeconds: durationSoFar(),
                    errorMessage: nil,
                    createdPlaylistName: nil
                )
                self.lastReport = report
                self.history.insert(report, at: 0)
                TransferHistoryStore.save(history)
                self.rematchQueue = results.filter { result in
                    guard case .alternate = result.confidence else { return false }
                    if acceptedRematchIds.contains(result.sourceTrack.id) { return false }
                    if skippedRematchIds.contains(result.sourceTrack.id) { return false }
                    if autoAcceptAlternates { return false }
                    return missingList.contains(where: { $0.id == result.sourceTrack.id })
                }
                clearRematchDecisions()
                self.isMigrating = false
                HapticManager.successNotification()
                return report
                
            case .writePlaylist:
                break
            }
            
            statusMessage = "Writing playlist to \(destinationType.displayName)…"
            self.progress = 0.75
            self.currentTrackTitle = "Creating playlist"
            self.currentTrackArtist = destinationType.displayName
            
            let playlistName = "SoundShift · from \(sourceType.displayName)"
            let playlistDescription = "Migrated \(transferable.count) tracks via SoundShift on \(Date().formatted(date: .abbreviated, time: .omitted)). Missing: \(missingList.count). Skipped existing: \(skippedExisting)."
            
            let created = try await destinationProvider.createPlaylist(
                name: playlistName,
                description: playlistDescription,
                tracks: transferable
            )
            
            var likesSaved = 0
            var likesWarning: String?
            if scope.transferFavorites {
                statusMessage = "Saving Liked Songs on \(destinationType.displayName)…"
                self.progress = 0.9
                do {
                    likesSaved = try await destinationProvider.saveTracksToLibrary(transferable)
                } catch {
                    likesWarning = "Playlist saved, but Liked Songs failed: \(error.localizedDescription)"
                }
            }
            
            // Refresh local snapshot with the new playlist
            servicesCoordinator.ingestRemotePlaylist(created)
            
            self.progress = 1.0
            self.processedCount = sourceTracks.count
            let likesNote: String
            if scope.transferFavorites {
                likesNote = likesWarning == nil ? ", \(likesSaved) liked" : ", likes incomplete"
            } else {
                likesNote = ""
            }
            let skipNote = skippedExisting > 0 ? ", \(skippedExisting) already there" : ""
            self.statusMessage = "Done — \(created.trackCount) in playlist\(likesNote)\(skipNote), \(missingList.count) missing"
            
            let duration = durationSoFar()
            let report = TransferExecutionReport(
                sourceProvider: sourceType,
                destinationProvider: destinationType,
                totalTracks: sourceTracks.count,
                successfullyTransferred: max(created.trackCount, likesSaved),
                skippedExisting: skippedExisting,
                missingTracks: missingList,
                alternatesAccepted: alternatesAccepted,
                durationSeconds: duration,
                errorMessage: nil,
                createdPlaylistName: created.title,
                warningMessage: likesWarning
            )
            
            self.lastReport = report
            self.history.insert(report, at: 0)
            TransferHistoryStore.save(history)
            // Keep only alternates that still need a Rematch Inbox decision (honest follow-up).
            rematchSnapshot = results.filter { result in
                guard case .alternate = result.confidence else { return false }
                if acceptedRematchIds.contains(result.sourceTrack.id) { return false }
                if skippedRematchIds.contains(result.sourceTrack.id) { return false }
                if autoAcceptAlternates { return false }
                return missingList.contains(where: { $0.id == result.sourceTrack.id })
            }
            self.rematchQueue = rematchSnapshot
            clearRematchDecisions()
            self.isMigrating = false
            if likesWarning != nil {
                HapticManager.lightImpact()
            } else {
                HapticManager.successNotification()
            }
            return report
        } catch {
            self.lastErrorMessage = error.localizedDescription
            self.statusMessage = "Migration failed"
            self.isMigrating = false
            HapticManager.errorNotification()
            
            // Preserve unresolved tracks so the report is not “MISSING 0” after a mid-flight fail.
            if !rematchSnapshot.isEmpty {
                rematchQueue = rematchSnapshot
            }
            
            let report = TransferExecutionReport(
                sourceProvider: sourceType,
                destinationProvider: destinationType,
                totalTracks: totalToProcess,
                successfullyTransferred: 0,
                missingTracks: missingList,
                alternatesAccepted: 0,
                durationSeconds: Date().timeIntervalSince(startTime),
                errorMessage: error.localizedDescription,
                createdPlaylistName: nil
            )
            self.lastReport = report
            self.history.insert(report, at: 0)
            TransferHistoryStore.save(history)
            return report
        }
    }
    
    // MARK: - Rematch Inbox
    
    public func resolveRematch(item: MatchResult, acceptCandidate: Bool) {
        let id = item.sourceTrack.id
        rematchQueue.removeAll(where: { $0.sourceTrack.id == id })
        if acceptCandidate {
            skippedRematchIds.remove(id)
            acceptedRematchIds.insert(id)
            // Keep match row for next migrate; alternate stays alternate but accepted.
            if let idx = lastMatchResults.firstIndex(where: { $0.sourceTrack.id == id }) {
                lastMatchResults[idx] = item
            } else {
                lastMatchResults.append(item)
            }
        } else {
            acceptedRematchIds.remove(id)
            skippedRematchIds.insert(id)
            if let idx = lastMatchResults.firstIndex(where: { $0.sourceTrack.id == id }) {
                let source = lastMatchResults[idx].sourceTrack
                lastMatchResults[idx] = MatchResult(
                    sourceTrack: source,
                    matchedTrack: nil,
                    confidence: .missing,
                    score: 0
                )
            }
        }
        HapticManager.lightImpact()
    }
    
    public func clearRematchDecisions() {
        acceptedRematchIds.removeAll()
        skippedRematchIds.removeAll()
    }
    
    /// Call when the user changes source/destination/selection so stale dry-run numbers cannot mislead.
    public func invalidateDryRunPreview() {
        lastDryRun = nil
        rematchQueue = []
        lastMatchResults = []
        clearRematchDecisions()
    }
    
    // MARK: - Helpers
    
    private static func trackBelongs(to type: MusicProviderType, track: UniversalTrack) -> Bool {
        switch type {
        case .spotify: return track.spotifyId != nil
        case .appleMusic: return track.appleMusicId != nil
        case .yandexMusic: return track.yandexId != nil
        }
    }
    
    private static func deduplicate(_ tracks: [UniversalTrack]) -> [UniversalTrack] {
        TrackDeduper.merge(tracks)
    }
    
    private static func isAlreadyInLibrary(
        _ matched: UniversalTrack,
        destinationLibrary: [UniversalTrack],
        source: UniversalTrack
    ) -> Bool {
        SkipPolicy.isAlreadyInLibrary(
            matched: matched,
            destinationLibrary: destinationLibrary,
            source: source
        )
    }
}
