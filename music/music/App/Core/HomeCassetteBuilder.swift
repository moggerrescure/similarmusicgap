import Foundation

/// Descriptor for Home “Friday Drops” cassettes (UI maps colors separately).
public struct HomeCassetteDescriptor: Equatable, Identifiable, Sendable {
    public let id: Int
    public let title: String
    public let subtitle: String
    public let sideText: String
    public let tapeType: String
    public let tapeLength: String
    public let trackIsrc: String
    public let isShowcase: Bool
    
    public init(
        id: Int,
        title: String,
        subtitle: String,
        sideText: String,
        tapeType: String,
        tapeLength: String,
        trackIsrc: String,
        isShowcase: Bool
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.sideText = sideText
        self.tapeType = tapeType
        self.tapeLength = tapeLength
        self.trackIsrc = trackIsrc
        self.isShowcase = isShowcase
    }
}

/// Builds Home cassette shelf from synced library, or honest showcase fixtures.
public enum HomeCassetteBuilder {
    public static let showcaseFixtures: [HomeCassetteDescriptor] = [
        HomeCassetteDescriptor(
            id: 201, title: "Night Drive Pulse", subtitle: "Dark Synthwave • Showcase",
            sideText: "SIDE A", tapeType: "TYPE II • HIGH BIAS", tapeLength: "60 MIN",
            trackIsrc: "TAPE-201", isShowcase: true
        ),
        HomeCassetteDescriptor(
            id: 202, title: "Silk Lo-Fi Flow", subtitle: "Chill Focus • Showcase",
            sideText: "SIDE A", tapeType: "CHROME CrO2", tapeLength: "45 MIN",
            trackIsrc: "TAPE-202", isShowcase: true
        ),
        HomeCassetteDescriptor(
            id: 203, title: "Tokyo Drift Phonk", subtitle: "Drift • Showcase",
            sideText: "SIDE A", tapeType: "TYPE I", tapeLength: "45 MIN",
            trackIsrc: "TAPE-203", isShowcase: true
        ),
        HomeCassetteDescriptor(
            id: 204, title: "Afterhours House", subtitle: "Club • Showcase",
            sideText: "SIDE A", tapeType: "METAL", tapeLength: "60 MIN",
            trackIsrc: "TAPE-204", isShowcase: true
        )
    ]
    
    public static func build(
        playlists: [UniversalPlaylist],
        tracks: [UniversalTrack],
        limit: Int = 4
    ) -> [HomeCassetteDescriptor] {
        var result: [HomeCassetteDescriptor] = []
        
        for (idx, playlist) in playlists.prefix(limit).enumerated() {
            let count = max(playlist.trackCount, playlist.tracks.count)
            let mins = max(1, playlist.tracks.reduce(0) { $0 + $1.durationMs } / 60_000)
            let length = mins > 0 && !playlist.tracks.isEmpty ? "\(mins) MIN" : "MIX"
            result.append(
                HomeCassetteDescriptor(
                    id: 1000 + idx,
                    title: playlist.title,
                    subtitle: "\(playlist.providerType.displayName) • \(count) tracks",
                    sideText: "SIDE A",
                    tapeType: "FROM LIBRARY",
                    tapeLength: length,
                    trackIsrc: playlist.tracks.first?.isrc ?? "LIB-\(idx)",
                    isShowcase: false
                )
            )
        }
        
        if result.count < limit, !tracks.isEmpty {
            let chunk = 8
            var offset = 0
            var idx = result.count
            while result.count < limit, offset < tracks.count {
                let slice = Array(tracks[offset..<min(offset + chunk, tracks.count)])
                offset += chunk
                guard !slice.isEmpty else { break }
                let mins = max(1, slice.reduce(0) { $0 + $1.durationMs } / 60_000)
                let lead = slice.first?.primaryArtist ?? "Mix"
                result.append(
                    HomeCassetteDescriptor(
                        id: 2000 + idx,
                        title: "Library Mix \(idx + 1)",
                        subtitle: "\(lead) + \(slice.count - 1) more • \(slice.count) tracks",
                        sideText: "SIDE A",
                        tapeType: "FROM LIBRARY",
                        tapeLength: "\(mins) MIN",
                        trackIsrc: slice.first?.isrc ?? "MIX-\(idx)",
                        isShowcase: false
                    )
                )
                idx += 1
            }
        }
        
        if result.isEmpty {
            return Array(showcaseFixtures.prefix(limit))
        }
        return result
    }
    
    public static func sectionTitle(for cassettes: [HomeCassetteDescriptor]) -> String {
        if cassettes.isEmpty || cassettes.contains(where: \.isShowcase) {
            return "FRIDAY DROPS · SHOWCASE"
        }
        return "FRIDAY DROPS · FROM LIBRARY"
    }
}
