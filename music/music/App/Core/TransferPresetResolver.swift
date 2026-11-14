import Foundation

/// Transfer scope presets (Create tab) — pure selection logic for tests & UI.
public enum TransferPresetKind: String, CaseIterable, Identifiable, Sendable {
    case full
    case favorites
    case delta
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .full: return "Full Vault"
        case .favorites: return "Favorites Only"
        case .delta: return "Delta (New Only)"
        }
    }
}

public struct TransferPresetSelection: Equatable, Sendable {
    public let trackIds: Set<UUID>
    public let playlistIds: Set<UUID>
    public let transferFavorites: Bool
    
    public init(trackIds: Set<UUID>, playlistIds: Set<UUID>, transferFavorites: Bool) {
        self.trackIds = trackIds
        self.playlistIds = playlistIds
        self.transferFavorites = transferFavorites
    }
}

/// Resolves which liked tracks + playlists a Create-tab preset should select.
public enum TransferPresetResolver {
    /// Days window for Delta (New Only).
    public static let deltaWindowDays: Int = 30
    
    public static func resolve(
        preset: TransferPresetKind,
        likedTracks: [UniversalTrack],
        playlists: [UniversalPlaylist],
        now: Date = Date()
    ) -> TransferPresetSelection {
        switch preset {
        case .favorites:
            // Liked / favorites only — no playlist rows.
            return TransferPresetSelection(
                trackIds: Set(likedTracks.map(\.id)),
                playlistIds: [],
                transferFavorites: true
            )
            
        case .full:
            // Liked songs + every track from source playlists.
            var ids = Set(likedTracks.map(\.id))
            var playlistIds = Set<UUID>()
            for playlist in playlists {
                playlistIds.insert(playlist.id)
                for track in playlist.tracks {
                    ids.insert(track.id)
                }
            }
            return TransferPresetSelection(
                trackIds: ids,
                playlistIds: playlistIds,
                transferFavorites: true
            )
            
        case .delta:
            let cutoff = Calendar.current.date(
                byAdding: .day,
                value: -deltaWindowDays,
                to: now
            ) ?? Date.distantPast
            let recent = likedTracks.filter { $0.addedAt >= cutoff }
            let chosen = recent.isEmpty ? likedTracks : recent
            return TransferPresetSelection(
                trackIds: Set(chosen.map(\.id)),
                playlistIds: [],
                transferFavorites: false
            )
        }
    }
    
    /// Ordered, deduplicated tracks for the archive UI under a preset.
    public static func tracks(
        preset: TransferPresetKind,
        likedTracks: [UniversalTrack],
        playlists: [UniversalPlaylist],
        now: Date = Date()
    ) -> [UniversalTrack] {
        let selection = resolve(
            preset: preset,
            likedTracks: likedTracks,
            playlists: playlists,
            now: now
        )
        var seen = Set<UUID>()
        var ordered: [UniversalTrack] = []
        
        func append(_ track: UniversalTrack) {
            guard selection.trackIds.contains(track.id), !seen.contains(track.id) else { return }
            seen.insert(track.id)
            ordered.append(track)
        }
        
        for track in likedTracks { append(track) }
        if preset == .full {
            for playlist in playlists {
                for track in playlist.tracks { append(track) }
            }
        }
        return ordered
    }
}
