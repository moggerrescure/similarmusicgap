import Foundation

/// Conflict resolution policy for target service (P2 - T11)
public enum ConflictPolicy: String, Codable, CaseIterable, Identifiable {
    case skip = "Skip Existing"
    case merge = "Merge"
    case overwrite = "Overwrite"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .skip: return "Don't duplicate tracks that already exist in destination"
        case .merge: return "Append incoming tracks to destination playlist"
        case .overwrite: return "Replace target playlist tracks with source tracks"
        }
    }
}

/// Transfer item scope
public struct TransferScope: Codable, Equatable {
    public var transferFavorites: Bool = true
    public var selectedPlaylistIds: Set<UUID> = []
    
    public init(transferFavorites: Bool = true, selectedPlaylistIds: Set<UUID> = []) {
        self.transferFavorites = transferFavorites
        self.selectedPlaylistIds = selectedPlaylistIds
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
    public let missingTracks: [UniversalTrack]
    public let alternatesAccepted: Int
    public let durationSeconds: Double
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        sourceProvider: MusicProviderType,
        destinationProvider: MusicProviderType,
        totalTracks: Int,
        successfullyTransferred: Int,
        missingTracks: [UniversalTrack] = [],
        alternatesAccepted: Int = 0,
        durationSeconds: Double = 0.0
    ) {
        self.id = id
        self.timestamp = timestamp
        self.sourceProvider = sourceProvider
        self.destinationProvider = destinationProvider
        self.totalTracks = totalTracks
        self.successfullyTransferred = successfullyTransferred
        self.missingTracks = missingTracks
        self.alternatesAccepted = alternatesAccepted
        self.durationSeconds = durationSeconds
    }
    
    public var shareableText: String {
        """
        SoundShift Migration Report
        =============================
        From: \(sourceProvider.displayName)
        To:   \(destinationProvider.displayName)
        Date: \(timestamp.formatted(date: .abbreviated, time: .shortened))
        
        • Successfully Transferred: \(successfullyTransferred) / \(totalTracks) tracks (\(String(format: "%.1f", (Double(successfullyTransferred) / max(1.0, Double(totalTracks))) * 100))%)
        • Alternates Matched:       \(alternatesAccepted)
        • Unresolved / Missing:     \(missingTracks.count)
        
        \(missingTracks.isEmpty ? "All tracks matched with precision." : "Unresolved tracks:\n" + missingTracks.prefix(10).map { "- \($0.title) — \($0.primaryArtist)" }.joined(separator: "\n"))
        """
    }
}

