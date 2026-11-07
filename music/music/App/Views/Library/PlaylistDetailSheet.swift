import SwiftUI

/// Luxury Playlist Detail Sheet: track playback, reordering, and management
public struct PlaylistDetailSheet: View {
    public let playlist: UniversalPlaylist
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var playlistTracks: [UniversalTrack] = []
    
    public init(playlist: UniversalPlaylist) {
        self.playlist = playlist
        _playlistTracks = State(initialValue: playlist.tracks)
    }
    
    private var totalDurationMinutes: Int {
        let totalMs = playlistTracks.reduce(0) { $0 + $1.durationMs }
        return totalMs / 60000
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Ambient Gradient Wash
                AmbientWashBackgroundView()
                
                VStack(spacing: 0) {
                    headerSection
                    trackListSection
                }
            }
            .navigationTitle(playlist.title)
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(PastelTheme.pastelOat)
                }
            }
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 14) {
            // Artwork Squircle
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PastelTheme.pastelOat, Color(hex: "#1E293B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                    )
                    .shadow(color: PastelTheme.pastelOat.opacity(0.2), radius: 14, y: 6)
                
                Image(systemName: "music.note.list")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(PastelTheme.textOnOat)
            }
            
            VStack(spacing: 4) {
                Text(playlist.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                
                if let desc = playlist.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 13))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                
                HStack(spacing: 6) {
                    Text("\(playlistTracks.count) tracks")
                    Text("•")
                    Text("\(totalDurationMinutes) min")
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(PastelTheme.textTertiary)
            }
            
            // Play All Button
            if !playlistTracks.isEmpty {
                Button {
                    HapticManager.successNotification()
                    player.play(track: playlistTracks[0], in: playlistTracks)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Play All")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(PastelTheme.textOnOat)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(PastelTheme.pastelOat)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 16)
    }
    
    // MARK: - Track List Section
    @ViewBuilder
    private var trackListSection: some View {
        if playlistTracks.isEmpty {
            Spacer()
            Text("No tracks in this playlist yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(PastelTheme.textTertiary)
            Spacer()
        } else {
            List {
                ForEach(playlistTracks) { track in
                    PlaylistTrackRow(
                        track: track,
                        isCurrent: player.currentTrack == track,
                        isPlaying: player.currentTrack == track && player.isPlaying,
                        isFavorite: player.isFavorite(track: track),
                        onPlayTap: {
                            if player.currentTrack == track {
                                player.togglePlayPause()
                            } else {
                                player.play(track: track, in: playlistTracks)
                            }
                        },
                        onFavoriteTap: {
                            HapticManager.lightImpact()
                            player.toggleFavorite(track: track)
                        }
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: removeTracks)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }
    
    private func removeTracks(at offsets: IndexSet) {
        for idx in offsets {
            let track = playlistTracks[idx]
            coordinator.removeTrackFromPlaylist(track: track, playlistId: playlist.id)
        }
        playlistTracks.remove(atOffsets: offsets)
        HapticManager.lightImpact()
    }
}

// MARK: - Playlist Track Row
private struct PlaylistTrackRow: View {
    let track: UniversalTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isFavorite: Bool
    let onPlayTap: () -> Void
    let onFavoriteTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlayTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isCurrent ? PastelTheme.pastelOat.opacity(0.18) : PastelTheme.cardSubtle)
                        .frame(width: 40, height: 40)
                    
                    if isPlaying {
                        WaveformBarsView()
                            .frame(width: 20, height: 14)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isCurrent ? PastelTheme.pastelOat : PastelTheme.textPrimary)
                    .lineLimit(1)
                
                Text(track.primaryArtist)
                    .font(.system(size: 12))
                    .foregroundColor(PastelTheme.textSecondary)
                    .lineLimit(1)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onPlayTap)
            
            Spacer()
            
            // Trailing Action Area (Strictly aligned on the same horizontal level across every song)
            HStack(spacing: 8) {
                // Provider Brand Badges (Vertically centered at height 32)
                HStack(spacing: 4) {
                    if track.spotifyId != nil {
                        PlatformBrandBadgeView(type: .spotify, size: 14)
                    }
                    if track.appleMusicId != nil {
                        PlatformBrandBadgeView(type: .appleMusic, size: 14)
                    }
                    if track.yandexId != nil {
                        PlatformBrandBadgeView(type: .yandexMusic, size: 14)
                    }
                }
                .frame(height: 32, alignment: .trailing)
                
                Menu {
                    Button {
                        onFavoriteTap()
                    } label: {
                        Label(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "heart.slash" : "heart")
                    }
                    Button {
                        onPlayTap()
                    } label: {
                        Label("Play Now", systemImage: "play.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(PastelTheme.textTertiary)
                        .frame(width: 32, height: 32, alignment: .center)
                        .contentShape(Rectangle())
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            .frame(height: 32, alignment: .center)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
