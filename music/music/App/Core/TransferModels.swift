import Foundation

/// Conflict resolution policy for target service (P2 - T11)
public enum ConflictPolicy: String, Codable, CaseIterable, Identifiable {
    case skip = "Skip Existing"
    case merge = "Merge"
    case overwrite = "Overwrite"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .skip:
            return "Skip tracks already in the destination library. Still creates a new SoundShift playlist for the rest."
        case .merge:
            return "Include every match, even if already liked. Always creates a new playlist (does not edit existing ones)."
        case .overwrite:
            return "Not available yet — same as Merge until in-place playlist replace ships."
        }
    }
    
    /// Policies with distinct write behavior today (Overwrite is Merge until in-place replace exists).
    public static var implementedCases: [ConflictPolicy] { [.skip, .merge] }
}

/// Transfer item scope
public struct TransferScope: Codable, Equatable {
    public var transferFavorites: Bool = true
    public var selectedPlaylistIds: Set<UUID> = []
    public var selectedTrackIds: Set<UUID>? = nil
    
    public init(
        transferFavorites: Bool = true,
        selectedPlaylistIds: Set<UUID> = [],
        selectedTrackIds: Set<UUID>? = nil
    ) {
        self.transferFavorites = transferFavorites
        self.selectedPlaylistIds = selectedPlaylistIds
        self.selectedTrackIds = selectedTrackIds
    }
}

/// Instant Dry-Run Preview calculation (P1 - T6)
public struct DryRunSummary: Codable, Equatable {
    public let totalTracks: Int
    public let exactMatchesCount: Int
    public let alternateMatchesCount: Int
    public let missingCount: Int
    
    public var matchRatePercentage: Double {
        guard totalTracks > 0 else { return 0.0 }
        return (Double(exactMatchesCount + alternateMatchesCount) / Double(totalTracks)) * 100.0
    }
    
    public init(
        totalTracks: Int,
        exactMatchesCount: Int,
        alternateMatchesCount: Int,
        missingCount: Int
    ) {
        self.totalTracks = totalTracks
        self.exactMatchesCount = exactMatchesCount
        self.alternateMatchesCount = alternateMatchesCount
        self.missingCount = missingCount
    }
}

/// Completed migration report (P0 - T8, T12, T13)
public struct TransferExecutionReport: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let sourceProvider: MusicProviderType
    public let destinationProvider: MusicProviderType
    public let totalTracks: Int
    public let successfullyTransferred: Int
    /// Matched tracks already on destination that Skip policy left out of the write.
    public let skippedExisting: Int
    public let missingTracks: [UniversalTrack]
    public let alternatesAccepted: Int
    public let durationSeconds: Double
    public let errorMessage: String?
    public let createdPlaylistName: String?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sourceProvider: MusicProviderType,
        destinationProvider: MusicProviderType,
        totalTracks: Int,
        successfullyTransferred: Int,
        skippedExisting: Int = 0,
        missingTracks: [UniversalTrack] = [],
        alternatesAccepted: Int = 0,
        durationSeconds: Double = 0.0,
        errorMessage: String? = nil,
        createdPlaylistName: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sourceProvider = sourceProvider
        self.destinationProvider = destinationProvider
        self.totalTracks = totalTracks
        self.successfullyTransferred = successfullyTransferred
        self.skippedExisting = skippedExisting
        self.missingTracks = missingTracks
        self.alternatesAccepted = alternatesAccepted
        self.durationSeconds = durationSeconds
        self.errorMessage = errorMessage
        self.createdPlaylistName = createdPlaylistName
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        timestamp = try c.decode(Date.self, forKey: .timestamp)
        sourceProvider = try c.decode(MusicProviderType.self, forKey: .sourceProvider)
        destinationProvider = try c.decode(MusicProviderType.self, forKey: .destinationProvider)
        totalTracks = try c.decode(Int.self, forKey: .totalTracks)
        successfullyTransferred = try c.decode(Int.self, forKey: .successfullyTransferred)
        skippedExisting = try c.decodeIfPresent(Int.self, forKey: .skippedExisting) ?? 0
        missingTracks = try c.decode([UniversalTrack].self, forKey: .missingTracks)
        alternatesAccepted = try c.decode(Int.self, forKey: .alternatesAccepted)
        durationSeconds = try c.decode(Double.self, forKey: .durationSeconds)
        errorMessage = try c.decodeIfPresent(String.self, forKey: .errorMessage)
        createdPlaylistName = try c.decodeIfPresent(String.self, forKey: .createdPlaylistName)
    }
    
    /// Soft success: wrote tracks, or Skip left nothing new to write.
    public var didSucceed: Bool {
        errorMessage == nil && (successfullyTransferred > 0 || skippedExisting > 0)
    }
    
    public var isHardFailure: Bool {
        errorMessage != nil
    }
    
    /// True when Skip policy found everything already on destination.
    public var isNothingNewSuccess: Bool {
        didSucceed && successfullyTransferred == 0 && skippedExisting > 0
    }
    
    public var matchRate: Double {
        guard totalTracks > 0 else { return 0 }
        let covered = successfullyTransferred + skippedExisting
        return (Double(min(covered, totalTracks)) / Double(totalTracks)) * 100.0
    }
    
    public var shareableText: String {
        let header = didSucceed ? "SoundShift Migration Report" : "SoundShift Migration Failed"
        let body: String
        if let errorMessage {
            body = "Error: \(errorMessage)"
        } else if isNothingNewSuccess {
            body = """
            • Nothing new to write — \(skippedExisting) already on destination
            • Unresolved / Missing:     \(missingTracks.count)
            
            \(missingTracks.isEmpty ? "Destination already had every matched track." : "Unresolved tracks:\n" + missingTracks.prefix(10).map { "- \($0.title) — \($0.primaryArtist)" }.joined(separator: "\n"))
            """
        } else {
            body = """
            • Successfully Transferred: \(successfullyTransferred) / \(totalTracks) tracks (\(String(format: "%.1f", matchRate))%)
            • Already on destination:   \(skippedExisting)
            • Alternates Matched:       \(alternatesAccepted)
            • Unresolved / Missing:     \(missingTracks.count)
            \(createdPlaylistName.map { "• Playlist: \($0)" } ?? "")
            
            \(missingTracks.isEmpty ? "All selected tracks matched." : "Unresolved tracks:\n" + missingTracks.prefix(10).map { "- \($0.title) — \($0.primaryArtist)" }.joined(separator: "\n"))
            """
        }
        return """
        \(header)
        =============================
        From: \(sourceProvider.displayName)
        To:   \(destinationProvider.displayName)
        Date: \(timestamp.formatted(date: .abbreviated, time: .shortened))
        
        \(body)
        """
    }
}
