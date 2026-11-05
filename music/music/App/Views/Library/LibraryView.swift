import SwiftUI

/// Screen: Unified Cross-Service Library & Instant Search
public struct LibraryView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedFilter: LibraryFilter = .all
    @State private var showingDuplicatesSheet: Bool = false
    
    // Sample demo tracks if coordinator is empty
    private var allTracks: [UniversalTrack] {
        if coordinator.allTracks.isEmpty {
            return [
                UniversalTrack(isrc: "USUM71703861", title: "Starboy", artists: ["The Weeknd", "Daft Punk"], album: "Starboy", durationMs: 230453, yandexId: "29871638", spotifyId: "7a26vX02Y4vYj9P6RrqU04"),
                UniversalTrack(isrc: "GBUM71505080", title: "The Less I Know the Better", artists: ["Tame Impala"], album: "Currents", durationMs: 216320, spotifyId: "6K4t31amVTKVgPeRoxXErq"),
                UniversalTrack(isrc: "USAT21900122", title: "Blinding Lights", artists: ["The Weeknd"], album: "After Hours", durationMs: 200040, appleMusicId: "1499378607"),
                UniversalTrack(isrc: "RUAA12000042", title: "Где нас нет", artists: ["Oxxxymiron"], album: "ГОРГОРОД", durationMs: 265000, yandexId: "24981120"),
                UniversalTrack(isrc: "FRUM71300088", title: "Instant Crush", artists: ["Daft Punk", "Julian Casablancas"], album: "Random Access Memories", durationMs: 337560, yandexId: "14589231", spotifyId: "2bpgKp31sOVoTeStOXzi8C"),
                UniversalTrack(isrc: "USWB11200021", title: "Midnight City", artists: ["M83"], album: "Hurry Up, We're Dreaming", durationMs: 243000, spotifyId: "1eyzqe2QqGZUmfcPZtrIyt", appleMusicId: "466487841")
            ]
        }
        return coordinator.allTracks
    }
    
    private var duplicates: [DuplicateGroup] {
        DuplicatesEngine.shared.findDuplicates(in: allTracks)
    }
    
    private var favoriteCount: Int {
        allTracks.filter { player.isFavorite(track: $0) }.count
    }
    
    private var filteredTracks: [UniversalTrack] {
        var list = allTracks
        
        switch selectedFilter {
        case .all:
            break
        case .favorites:
            list = list.filter { player.isFavorite(track: $0) }
        case .duplicates:
            let dupKeys = Set(duplicates.map { $0.canonicalTitle })
            list = list.filter { dupKeys.contains($0.title) }
        case .spotify:
            list = list.filter { $0.spotifyId != nil }
        case .appleMusic:
            list = list.filter { $0.appleMusicId != nil }
        case .yandexMusic:
            list = list.filter { $0.yandexId != nil }
        }
        
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.primaryArtist.lowercased().contains(query) ||
                ($0.album?.lowercased().contains(query) ?? false)
            }
        }
        return list
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Prominent Dedicated Apple Search Bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        TextField("Search songs, artists, albums", text: $searchText)
                            .font(.system(size: 15))
                            .foregroundColor(PastelTheme.textPrimary)
                            .autocorrectionDisabled()
                        
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    
                    // MARK: - Filter Chip Strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                title: "All (\(allTracks.count))",
                                isSelected: selectedFilter == .all
                            ) {
                                selectedFilter = .all
                            }
                            
                            FilterChip(
                                title: "Favorites (\(favoriteCount))",
                                isSelected: selectedFilter == .favorites,
                                icon: "heart.fill"
                            ) {
                                selectedFilter = .favorites
                            }
                            
                            if !duplicates.isEmpty {
                                FilterChip(
                                    title: "Duplicates (\(duplicates.count))",
                                    isSelected: selectedFilter == .duplicates
                                ) {
                                    selectedFilter = .duplicates
                                }
                            }
                            
                            FilterChip(title: "Spotify", isSelected: selectedFilter == .spotify) {
                                selectedFilter = .spotify
                            }
                            
                            FilterChip(title: "Apple Music", isSelected: selectedFilter == .appleMusic) {
                                selectedFilter = .appleMusic
                            }
                            
                            FilterChip(title: "Yandex Music", isSelected: selectedFilter == .yandexMusic) {
                                selectedFilter = .yandexMusic
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    // MARK: - Duplicates Banner
                    if selectedFilter == .duplicates && !duplicates.isEmpty {
                        HStack {
                            Image(systemName: "square.stack.3d.down.right.fill")
                                .foregroundColor(PastelTheme.amberWarning)
                            Text("\(duplicates.count) cross-library duplicates found")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            Spacer()
                            Button("Inspect") {
                                showingDuplicatesSheet = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PastelTheme.pastelOat)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    // MARK: - Track List
                    if filteredTracks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "music.note.list")
                                .font(.system(size: 36))
                                .foregroundColor(PastelTheme.textTertiary)
                            Text("No tracks found")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTracks) { track in
                                TrackRow(
                                    track: track,
                                    isCurrent: player.currentTrack == track,
                                    isPlaying: player.currentTrack == track && player.isPlaying,
                                    isFavorite: player.isFavorite(track: track),
                                    loopMode: player.currentTrack == track ? player.loopMode : nil,
                                    onPlayTap: {
                                        if player.currentTrack == track {
                                            player.togglePlayPause()
                                        } else {
                                            player.play(track: track, in: filteredTracks)
                                        }
                                    },
                                    onFavoriteTap: {
                                        player.toggleFavorite(track: track)
                                    },
                                    onLoopTap: {
                                        if player.currentTrack == track {
                                            player.toggleLoopMode()
                                        }
                                    },
                                    onRewindTap: {
                                        player.skipBackward(by: 15)
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .padding(.bottom, player.currentTrack != nil ? 70 : 10)
                    }
                }
            }
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
            .sheet(isPresented: $showingDuplicatesSheet) {
                DuplicatesInspectorView(duplicates: duplicates)
            }
        }
    }
}

// MARK: - Track Row Component
private struct TrackRow: View {
    let track: UniversalTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isFavorite: Bool
    let loopMode: LoopMode?
    let onPlayTap: () -> Void
    let onFavoriteTap: () -> Void
    let onLoopTap: () -> Void
    var onRewindTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // Play / Waveform Artwork Button
            Button(action: onPlayTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isCurrent ? PastelTheme.pastelOat.opacity(0.15) : PastelTheme.cardSubtle)
                        .frame(width: 44, height: 44)
                    
                    if isPlaying {
                        WaveformBarsView()
                    } else if isCurrent {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14))
                            .foregroundColor(PastelTheme.pastelOat)
                    } else {
                        Image(systemName: "music.note")
                            .font(.system(size: 15))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                }
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Title & Artist (tapping anywhere plays the song)
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(isCurrent ? PastelTheme.pastelOat : PastelTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(track.primaryArtist)
                        .foregroundColor(PastelTheme.textSecondary)
                    if let album = track.album {
                        Text("•")
                            .foregroundColor(PastelTheme.textTertiary)
                        Text(album)
                            .foregroundColor(PastelTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 12))
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onPlayTap)
            
            Spacer()
            
            // Rewind 15s Button (if active)
            if isCurrent, let onRewindTap = onRewindTap {
                Button(action: onRewindTap) {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PastelTheme.textSecondary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Loop Mode Indicator (if currently active)
            if let loop = loopMode {
                Button(action: onLoopTap) {
                    Image(systemName: loop.iconName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(loop != .off ? PastelTheme.pastelOat : PastelTheme.textTertiary)
                        .frame(width: 26, height: 26)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
            
            // Favorite Button
            Button(action: onFavoriteTap) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(isFavorite ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Platform Badges & Duration
            HStack(spacing: 5) {
                if track.spotifyId != nil {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#10B981"))
                }
                if track.appleMusicId != nil {
                    Image(systemName: "applelogo")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#FB7185"))
                }
                if track.yandexId != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#FBBF24"))
                }
                
                Text(track.formattedDuration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(PastelTheme.textTertiary)
                    .padding(.leading, 2)
            }
        }
        .padding(10)
        .background(isCurrent ? PastelTheme.cardSubtle : PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isCurrent ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 0.8)
        )
        .contextMenu {
            Button(action: onPlayTap) {
                Label(isPlaying ? "Pause" : "Play Now", systemImage: isPlaying ? "pause.fill" : "play.fill")
            }
            Button(action: onFavoriteTap) {
                Label(isFavorite ? "Remove from Favorites" : "Add to Favorites", systemImage: isFavorite ? "heart.slash" : "heart")
            }
            if track.spotifyId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .spotify) } label: {
                    Label("Open in Spotify", systemImage: "arrow.up.right")
                }
            }
            if track.appleMusicId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .appleMusic) } label: {
                    Label("Open in Apple Music", systemImage: "arrow.up.right")
                }
            }
            if track.yandexId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .yandexMusic) } label: {
                    Label("Open in Yandex Music", systemImage: "arrow.up.right")
                }
            }
        }
    }
}

// MARK: - Animated Waveform Bars
private struct WaveformBarsView: View {
    @State private var anim: Bool = false
    
    var body: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 1)
                .fill(PastelTheme.pastelOat)
                .frame(width: 3, height: anim ? 14 : 6)
            RoundedRectangle(cornerRadius: 1)
                .fill(PastelTheme.pastelOat)
                .frame(width: 3, height: anim ? 8 : 16)
            RoundedRectangle(cornerRadius: 1)
                .fill(PastelTheme.pastelOat)
                .frame(width: 3, height: anim ? 16 : 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                anim.toggle()
            }
        }
    }
}

// MARK: - Filter Chip Component
private enum LibraryFilter {
    case all, favorites, duplicates, spotify, appleMusic, yandexMusic
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            HStack(spacing: 5) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(isSelected ? PastelTheme.pastelOat : PastelTheme.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : PastelTheme.cardBorder, lineWidth: 0.8)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
}

#if DEBUG
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
#endif
