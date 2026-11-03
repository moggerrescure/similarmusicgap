import Foundation
import SwiftUI

/// Acoustic dimensions for radar analysis (S1, S2)
public struct AcousticProfile: Codable, Equatable {
    public var energy: Double          // 0.0 to 1.0
    public var valence: Double         // 0.0 (melancholic) to 1.0 (euphoric)
    public var danceability: Double    // 0.0 to 1.0
    public var acousticness: Double    // 0.0 to 1.0
    public var focusFlow: Double       // 0.0 to 1.0 (instrumental / focus)
    
    public init(
        energy: Double = 0.72,
        valence: Double = 0.44,
        danceability: Double = 0.68,
        acousticness: Double = 0.35,
        focusFlow: Double = 0.81
    ) {
        self.energy = energy
        self.valence = valence
        self.danceability = danceability
        self.acousticness = acousticness
        self.focusFlow = focusFlow
    }
}

/// Decade affinity distribution (S2)
public struct DecadeShare: Identifiable, Codable, Equatable {
    public var id: String { decade }
    public let decade: String
    public let percentage: Double
    public let colorHex: String
    
    public init(decade: String, percentage: Double, colorHex: String) {
        self.decade = decade
        self.percentage = percentage
        self.colorHex = colorHex
    }
}

/// Listening mode / context cluster (S3)
public struct ListeningCluster: Identifiable, Codable, Equatable {
    public let id: String
    public let title: String
    public let icon: String
    public let vibeTag: String
    public let description: String
    public let percentage: Int
    public let colorHex: String
    
    public init(
        id: String,
        title: String,
        icon: String,
        vibeTag: String,
        description: String,
        percentage: Int,
        colorHex: String
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.vibeTag = vibeTag
        self.description = description
        self.percentage = percentage
        self.colorHex = colorHex
    }
}

/// Anonymous Taste Twin matching (SO3)
public struct TasteTwinMatch: Codable, Equatable {
    public let similarityScore: Double // e.g. 0.984 -> 98.4%
    public let twinLocationHint: String
    public let sharedNicheArtists: [String]
    public let rarityPercentile: Double // e.g. 0.04% of listeners
    
    public init(
        similarityScore: Double = 0.984,
        twinLocationHint: String = "Tokyo, Japan",
        sharedNicheArtists: [String] = ["The Weeknd", "Tame Impala", "Daft Punk"],
        rarityPercentile: Double = 0.04
    ) {
        self.similarityScore = similarityScore
        self.twinLocationHint = twinLocationHint
        self.sharedNicheArtists = sharedNicheArtists
        self.rarityPercentile = rarityPercentile
    }
}

/// Full comprehensive taste profile (S1, S2, S3, SO1)
public struct FullTasteProfile: Codable, Equatable {
    public let archetypeTitle: String
    public let aiInterpretation: String
    public let acousticProfile: AcousticProfile
    public let topArtists: [String]
    public let topGenres: [(genre: String, share: Int)]
    public let decadeDistribution: [DecadeShare]
    public let clusters: [ListeningCluster]
    public let tasteTwin: TasteTwinMatch
    public let totalAnalyzedTracks: Int
    
    public init(
        archetypeTitle: String,
        aiInterpretation: String,
        acousticProfile: AcousticProfile,
        topArtists: [String],
        topGenres: [(genre: String, share: Int)],
        decadeDistribution: [DecadeShare],
        clusters: [ListeningCluster],
        tasteTwin: TasteTwinMatch,
        totalAnalyzedTracks: Int
    ) {
        self.archetypeTitle = archetypeTitle
        self.aiInterpretation = aiInterpretation
        self.acousticProfile = acousticProfile
        self.topArtists = topArtists
        self.topGenres = topGenres
        self.decadeDistribution = decadeDistribution
        self.clusters = clusters
        self.tasteTwin = tasteTwin
        self.totalAnalyzedTracks = totalAnalyzedTracks
    }
    
    // Custom Codable for tuple
    enum CodingKeys: String, CodingKey {
        case archetypeTitle, aiInterpretation, acousticProfile, topArtists, decadeDistribution, clusters, tasteTwin, totalAnalyzedTracks
        case genresArray
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        archetypeTitle = try container.decode(String.self, forKey: .archetypeTitle)
        aiInterpretation = try container.decode(String.self, forKey: .aiInterpretation)
        acousticProfile = try container.decode(AcousticProfile.self, forKey: .acousticProfile)
        topArtists = try container.decode([String].self, forKey: .topArtists)
        decadeDistribution = try container.decode([DecadeShare].self, forKey: .decadeDistribution)
        clusters = try container.decode([ListeningCluster].self, forKey: .clusters)
        tasteTwin = try container.decode(TasteTwinMatch.self, forKey: .tasteTwin)
        totalAnalyzedTracks = try container.decode(Int.self, forKey: .totalAnalyzedTracks)
        topGenres = [("Synthwave / Indie", 42), ("Mid-90s Phonk", 28), ("Ambient Lo-Fi", 18), ("Alternative Rock", 12)]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(archetypeTitle, forKey: .archetypeTitle)
        try container.encode(aiInterpretation, forKey: .aiInterpretation)
        try container.encode(acousticProfile, forKey: .acousticProfile)
        try container.encode(topArtists, forKey: .topArtists)
        try container.encode(decadeDistribution, forKey: .decadeDistribution)
        try container.encode(clusters, forKey: .clusters)
        try container.encode(tasteTwin, forKey: .tasteTwin)
        try container.encode(totalAnalyzedTracks, forKey: .totalAnalyzedTracks)
    }
}

