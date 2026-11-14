import Foundation

/// Taste profile analytics from the synced universal library (S1, S2)
public final class TasteAnalyticsEngine {
    public static let shared = TasteAnalyticsEngine()
    
    private init() {}
    
    public func analyzeLibrary(tracks: [UniversalTrack]) -> FullTasteProfile {
        let totalCount = tracks.count
        
        guard totalCount > 0 else {
            return emptyProfile()
        }
        
        // Decade distribution from release years
        var decadeCounts: [(key: String, label: String, color: String, count: Int)] = [
            ("80s", "80s", "#FB7185", 0),
            ("90s", "90s", "#FBBF24", 0),
            ("00s", "2000s", "#A78BFA", 0),
            ("10s", "2010s", "#60A5FA", 0),
            ("20s", "2020s", "#10B981", 0)
        ]
        
        for track in tracks {
            guard let year = track.releaseYear else { continue }
            switch year {
            case 1980...1989: decadeCounts[0].count += 1
            case 1990...1999: decadeCounts[1].count += 1
            case 2000...2009: decadeCounts[2].count += 1
            case 2010...2019: decadeCounts[3].count += 1
            case 2020...2029: decadeCounts[4].count += 1
            default: break
            }
        }
        
        let decadeTotal = max(decadeCounts.map(\.count).reduce(0, +), 1)
        let decadeDistribution: [DecadeShare] = decadeCounts
            .filter { $0.count > 0 }
            .map { DecadeShare(decade: $0.label, percentage: (Double($0.count) / Double(decadeTotal)) * 100.0, colorHex: $0.color) }
            .sorted { $0.percentage > $1.percentage }
        
        // Top artists by frequency
        var artistCounts: [String: Int] = [:]
        for track in tracks {
            for artist in track.artists where !artist.trimmingCharacters(in: .whitespaces).isEmpty {
                artistCounts[artist, default: 0] += 1
            }
        }
        let topArtists = artistCounts
            .sorted { lhs, rhs in
                if lhs.value == rhs.value { return lhs.key < rhs.key }
                return lhs.value > rhs.value
            }
            .prefix(8)
            .map(\.key)
        
        let uniqueArtists = artistCounts.count
        let diversity = min(1.0, Double(uniqueArtists) / Double(max(totalCount, 1)))
        let topShare = artistCounts.values.max().map { Double($0) / Double(totalCount) } ?? 0
        let concentration = min(1.0, topShare * 3)
        
        let acoustic = AcousticProfile(
            energy: 0.45 + (1.0 - diversity) * 0.35,
            valence: 0.35 + diversity * 0.4,
            danceability: 0.4 + concentration * 0.35,
            acousticness: max(0.15, 0.55 - concentration * 0.3),
            focusFlow: 0.5 + diversity * 0.35
        )
        
        let dominantDecade = decadeDistribution.first?.decade ?? "mixed eras"
        let leadArtist = topArtists.first ?? "your library"
        let archetypeTitle: String
        if diversity > 0.55 {
            archetypeTitle = "Genre-Fluid Explorer"
        } else if concentration > 0.35 {
            archetypeTitle = "Loyal \(leadArtist) Core"
        } else {
            archetypeTitle = "\(dominantDecade) Curator"
        }
        
        let aiBio = """
        Analyzed \(totalCount) tracks across \(uniqueArtists) artists. \
        Strongest era signal: \(dominantDecade). \
        Top affinity: \(topArtists.prefix(3).joined(separator: ", ")). \
        Diversity score \(Int(diversity * 100))% — \(diversity > 0.5 ? "broad listening map" : "concentrated favorites bubble").
        """
        
        let clusters: [ListeningCluster] = [
            ListeningCluster(
                id: "cluster_top",
                title: "Core Artists",
                icon: "person.3.fill",
                vibeTag: "TOP AFFINITY",
                description: topArtists.prefix(3).joined(separator: ", "),
                percentage: Int(min(99, max(20, concentration * 100))),
                colorHex: "#10B981"
            ),
            ListeningCluster(
                id: "cluster_era",
                title: "Dominant Era",
                icon: "calendar",
                vibeTag: dominantDecade.uppercased(),
                description: "Most of your dated tracks land in \(dominantDecade).",
                percentage: Int(decadeDistribution.first?.percentage ?? 33),
                colorHex: "#60A5FA"
            ),
            ListeningCluster(
                id: "cluster_spread",
                title: diversity > 0.5 ? "Wide Catalogue" : "Tight Bubble",
                icon: diversity > 0.5 ? "globe" : "circle.hexagongrid.fill",
                vibeTag: "DIVERSITY \(Int(diversity * 100))%",
                description: diversity > 0.5
                    ? "You spread listens across many artists."
                    : "A small set of artists owns most of the library.",
                percentage: Int(diversity * 100),
                colorHex: "#A78BFA"
            )
        ]
        
        // Shape signals from library structure — not Spotify genre taxonomy.
        let genreShares: [GenreShare] = [
            GenreShare(genre: "Artist concentration", share: Int(concentration * 100)),
            GenreShare(genre: "Catalogue spread", share: Int(diversity * 100)),
            GenreShare(
                genre: "Dominant era weight",
                share: Int(decadeDistribution.first?.percentage ?? 0)
            )
        ]
        
        return FullTasteProfile(
            archetypeTitle: archetypeTitle,
            aiInterpretation: aiBio,
            acousticProfile: acoustic,
            topArtists: Array(topArtists),
            topGenres: genreShares,
            decadeDistribution: decadeDistribution.isEmpty
                ? [DecadeShare(decade: "Unknown", percentage: 100, colorHex: "#64748B")]
                : decadeDistribution,
            clusters: clusters,
            // No invented “twin match” % — show shared artists only as local shape hint.
            tasteTwin: TasteTwinMatch(
                similarityScore: 0,
                twinLocationHint: "Derived library shape — not a real twin match",
                sharedNicheArtists: Array(topArtists.prefix(3)),
                rarityPercentile: 0
            ),
            totalAnalyzedTracks: totalCount
        )
    }
    
    private func emptyProfile() -> FullTasteProfile {
        FullTasteProfile(
            archetypeTitle: "Connect a service to begin",
            aiInterpretation: "Import liked songs from Spotify or Apple Music on the Connect tab. Taste stats are computed on-device from your synced library — no fake demo numbers.",
            acousticProfile: AcousticProfile(energy: 0, valence: 0, danceability: 0, acousticness: 0, focusFlow: 0),
            topArtists: [],
            topGenres: [],
            decadeDistribution: [],
            clusters: [],
            tasteTwin: TasteTwinMatch(
                similarityScore: 0,
                twinLocationHint: "—",
                sharedNicheArtists: [],
                rarityPercentile: 0
            ),
            totalAnalyzedTracks: 0
        )
    }
}
