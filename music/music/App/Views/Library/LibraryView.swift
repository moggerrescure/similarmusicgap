import SwiftUI

/// Top-level library filter categories
public enum LibrarySegment: String, CaseIterable, Identifiable {
    case tracks = "Tracks"
    case playlists = "Playlists"
    case favorites = "Favorites"
    case duplicates = "Duplicates"
    
    public var id: String { rawValue }
}

/// Screen: Unified Cross-Service Library, Custom Playlists & Drag-and-Drop Reordering
public struct LibraryView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    
    @State private var searchText: String = ""
    @State private var selectedSegment: LibrarySegment = .tracks
    @State private var selectedProviderFilter: MusicProviderType? = nil
    
    // Sheets
    @State private var showingDuplicatesSheet: Bool = false
    @State private var showingCreatePlaylistSheet: Bool = false
    @State private var selectedPlaylistForDetail: UniversalPlaylist? = nil
    @State private var trackForAddToPlaylist: UniversalTrack? = nil
    
    // Reorder state (triggered by 1.5s long-press)
    @State private var isReordering: Bool = false
    @State private var liftedTrackId: UUID? = nil
    
    // Local list cache for interactive drag & drop
    @State private var customOrderedTracks: [UniversalTrack] = []
    
    // Sample mock tracks if coordinator is empty
    private var baseTracks: [UniversalTrack] {
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
    
    private var allTracks: [UniversalTrack] {
        if customOrderedTracks.count == baseTracks.count {
            return customOrderedTracks
        }
        return baseTracks
    }
    
    private var duplicates: [DuplicateGroup] {
        DuplicatesEngine.shared.findDuplicates(in: allTracks)
    }
    
    private var favoriteCount: Int {
        allTracks.filter { player.isFavorite(track: $0) }.count
    }
    
    private var playlists: [UniversalPlaylist] {
        if coordinator.allPlaylists.isEmpty {
            return [
                UniversalPlaylist(
                    providerPlaylistId: "pl_demo_1",
                    providerType: .spotify,
                    title: "Deep Focus Ambient",
                    description: "Atmospheric soundscapes for deep flow states",
                    trackCount: 3,
                    tracks: Array(baseTracks.prefix(3))
                ),
                UniversalPlaylist(
                    providerPlaylistId: "pl_demo_2",
                    providerType: .appleMusic,
                    title: "Late Night Drive",
                    description: "Electronic synthwave & dark pop anthems",
                    trackCount: 4,
                    tracks: Array(baseTracks.suffix(4))
                )
            ]
        }
        return coordinator.allPlaylists
    }
    
    private var filteredTracks: [UniversalTrack] {
        var list = allTracks
        
        switch selectedSegment {
        case .tracks:
            break
        case .playlists:
            break
        case .favorites:
            list = list.filter { player.isFavorite(track: $0) }
        case .duplicates:
            let dupKeys = Set(duplicates.map { $0.canonicalTitle })
            list = list.filter { dupKeys.contains($0.title) }
        }
        
        if let provider = selectedProviderFilter {
            switch provider {
            case .spotify:
                list = list.filter { $0.spotifyId != nil }
            case .appleMusic:
                list = list.filter { $0.appleMusicId != nil }
            case .yandexMusic:
                list = list.filter { $0.yandexId != nil }
            }
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
                // MARK: - Ambient Cosmic Stardust Background
                CosmicParticleBackgroundView(particleCount: 50)
                
                VStack(spacing: 0) {
                    // MARK: - Dedicated Search Bar
                    searchBar
                    
                    // MARK: - Category Segments (Tracks, Playlists, Favorites, Duplicates)
                    segmentBar
                    
                    // Provider Chips (Spotify, Apple Music, Yandex)
                    if selectedSegment != .playlists {
                        providerFilterStrip
                    }
                    
                    // Reorder Mode Active Banner
                    if isReordering {
                        reorderBanner
                    }
                    
                    // MARK: - Main Content Switcher
                    if selectedSegment == .playlists {
                        playlistsContentView
                    } else {
                        tracksContentView
                    }
                }
            }
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
            .toolbar {
                if selectedSegment == .playlists {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            HapticManager.lightImpact()
                            showingCreatePlaylistSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            HapticManager.lightImpact()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                isReordering.toggle()
                            }
                        } label: {
                            Image(systemName: isReordering ? "checkmark.circle.fill" : "arrow.up.arrow.down.circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(isReordering ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDuplicatesSheet) {
                DuplicatesInspectorView(duplicates: duplicates)
            }
            .sheet(isPresented: $showingCreatePlaylistSheet) {
                CreatePlaylistSheet()
            }
            .sheet(item: $selectedPlaylistForDetail) { playlist in
                PlaylistDetailSheet(playlist: playlist)
            }
            .sheet(item: $trackForAddToPlaylist) { track in
                AddToPlaylistSheet(track: track, playlists: playlists)
            }
            .onAppear {
                if customOrderedTracks.isEmpty {
                    customOrderedTracks = baseTracks
                }
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
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
    }
    
    // MARK: - Segment Bar
    private var segmentBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibrarySegment.allCases) { seg in
                    let isSel = selectedSegment == seg
                    let countText: String = {
                        switch seg {
                        case .tracks: return "(\(allTracks.count))"
                        case .playlists: return "(\(playlists.count))"
                        case .favorites: return "(\(favoriteCount))"
                        case .duplicates: return "(\(duplicates.count))"
                        }
                    }()
                    
                    Button {
                        HapticManager.lightImpact()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSegment = seg
                        }
                    } label: {
                        HStack(spacing: 5) {
                            if seg == .favorites {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(isSel ? PastelTheme.textOnOat : PastelTheme.emeraldSuccess)
                            }
                            Text("\(seg.rawValue) \(countText)")
                                .font(.system(size: 13, weight: isSel ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSel ? PastelTheme.textOnOat : PastelTheme.textSecondary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(isSel ? PastelTheme.pastelOat : PastelTheme.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSel ? Color.clear : PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Provider Filter Strip
    private var providerFilterStrip: some View {
        HStack(spacing: 8) {
            ForEach(MusicProviderType.allCases) { provider in
                let isSel = selectedProviderFilter == provider
                Button {
                    HapticManager.lightImpact()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        if selectedProviderFilter == provider {
                            selectedProviderFilter = nil
                        } else {
                            selectedProviderFilter = provider
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        PlatformBrandBadgeView(type: provider, size: 14)
                        Text(provider.displayName)
                            .font(.system(size: 11, weight: isSel ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSel ? PastelTheme.textPrimary : PastelTheme.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(isSel ? Color(hex: provider.brandColorHex).opacity(0.18) : PastelTheme.cardSubtle)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSel ? Color(hex: provider.brandColorHex).opacity(0.4) : PastelTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
    
    // MARK: - Reorder Active Banner
    private var reorderBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .foregroundColor(PastelTheme.amberWarning)
            Text("Reorder Mode Active • Hold & drag handles")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
            Spacer()
            Button("Done") {
                HapticManager.successNotification()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isReordering = false
                    liftedTrackId = nil
                }
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(PastelTheme.pastelOat)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(PastelTheme.cardSubtle)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(PastelTheme.amberWarning.opacity(0.4), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Playlists Content
    private var playlistsContentView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Prominent Create Playlist Card
                Button {
                    HapticManager.lightImpact()
                    showingCreatePlaylistSheet = true
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                                .foregroundColor(PastelTheme.pastelOat.opacity(0.6))
                                .frame(width: 52, height: 52)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Create New Playlist")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            
                            Text("Curate cross-service vault with custom cover")
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(PastelTheme.textTertiary)
                    }
                    .padding(14)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Existing Playlists
                ForEach(playlists) { pl in
                    Button {
                        HapticManager.lightImpact()
                        selectedPlaylistForDetail = pl
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [PastelTheme.pastelOat.opacity(0.85), Color(hex: "#1E293B")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 54, height: 54)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                                    )
                                
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(PastelTheme.textOnOat)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(pl.title)
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                    .lineLimit(1)
                                
                                Text("\(pl.tracks.count) tracks • \(pl.description ?? "Universal Vault")")
                                    .font(.system(size: 12))
                                    .foregroundColor(PastelTheme.textSecondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            // Play All mini button
                            if !pl.tracks.isEmpty {
                                Button {
                                    HapticManager.successNotification()
                                    player.play(track: pl.tracks[0], in: pl.tracks)
                                } label: {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(PastelTheme.textOnOat)
                                        .frame(width: 32, height: 32)
                                        .background(PastelTheme.pastelOat)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                        }
                        .padding(12)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .padding(.bottom, player.currentTrack != nil ? 70 : 10)
        }
    }
    
    // MARK: - Tracks Content (with 1.5s long-press drag-to-reorder)
    @ViewBuilder
    private var tracksContentView: some View {
        if filteredTracks.isEmpty {
            emptyTracksView
        } else {
            trackListView
        }
    }
    
    @ViewBuilder
    private var emptyTracksView: some View {
        Spacer()
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 38))
                .foregroundColor(PastelTheme.textTertiary)
            Text("No tracks found")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(PastelTheme.textSecondary)
        }
        Spacer()
    }
    
    @ViewBuilder
    private var trackListView: some View {
        List {
            ForEach(filteredTracks) { track in
                trackRowView(for: track)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .onMove(perform: moveTracks)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .environment(\.editMode, isReordering ? .constant(.active) : .constant(.inactive))
        #endif
        .padding(.bottom, player.currentTrack != nil ? 70 : 10)
    }
    
    @ViewBuilder
    private func trackRowView(for track: UniversalTrack) -> some View {
        let isCurr = player.currentTrack == track
        let isPlaying = isCurr && player.isPlaying
        let isFav = player.isFavorite(track: track)
        let isLifted = liftedTrackId == track.id
        
        TrackRow(
            track: track,
            isCurrent: isCurr,
            isPlaying: isPlaying,
            isFavorite: isFav,
            isReordering: isReordering,
            isLifted: isLifted,
            loopMode: isCurr ? player.loopMode : nil,
            onPlayTap: {
                if isCurr {
                    player.togglePlayPause()
                } else {
                    player.play(track: track, in: filteredTracks)
                }
            },
            onFavoriteTap: {
                HapticManager.lightImpact()
                player.toggleFavorite(track: track)
            },
            onLoopTap: {
                if isCurr {
                    player.toggleLoopMode()
                }
            },
            onRewindTap: {
                player.skipBackward(by: 15)
            },
            onAddToPlaylistTap: {
                trackForAddToPlaylist = track
            }
        )
        .scaleEffect(isLifted ? 1.03 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isLifted)
        .onLongPressGesture(minimumDuration: 1.5) {
            HapticManager.heavyImpact()
            liftedTrackId = track.id
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isReordering = true
            }
        }
    }
    
    private func moveTracks(from source: IndexSet, to destination: Int) {
        customOrderedTracks.move(fromOffsets: source, toOffset: destination)
        coordinator.reorderTracks(fromOffsets: source, toOffset: destination)
        HapticManager.lightImpact()
    }
}

// MARK: - Track Row Component with Independent Click Targets
private struct TrackRow: View {
    let track: UniversalTrack
    let isCurrent: Bool
    let isPlaying: Bool
    let isFavorite: Bool
    var isReordering: Bool = false
    var isLifted: Bool = false
    let loopMode: LoopMode?
    let onPlayTap: () -> Void
    let onFavoriteTap: () -> Void
    let onLoopTap: () -> Void
    var onRewindTap: (() -> Void)? = nil
    var onAddToPlaylistTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Independent Artwork / Playback Button
            Button(action: onPlayTap) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isCurrent ? PastelTheme.pastelOat.opacity(0.18) : PastelTheme.cardSubtle)
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
            
            // MARK: - Song Title & Artist (Tap to Play)
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
            
            // MARK: - Independent Favorite Heart (Clickable on ANY Track)
            Button(action: onFavoriteTap) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFavorite ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                    .scaleEffect(isFavorite ? 1.15 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isFavorite)
                    .frame(width: 34, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // MARK: - Options 3-Dots Menu
            Menu {
                if let onAddToPlaylistTap = onAddToPlaylistTap {
                    Button {
                        onAddToPlaylistTap()
                    } label: {
                        Label("Add to Playlist...", systemImage: "text.badge.plus")
                    }
                }
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PastelTheme.textTertiary)
                    .frame(width: 26, height: 32)
            }
            .buttonStyle(BorderlessButtonStyle())
            
            // Official Platform Badges
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
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isCurrent ? PastelTheme.cardBorderFocused.opacity(0.12) : PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(isLifted ? PastelTheme.amberWarning : (isCurrent ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder), lineWidth: isLifted ? 2 : 1)
        )
        .shadow(color: isLifted ? PastelTheme.amberWarning.opacity(0.3) : Color.clear, radius: 10, y: 4)
    }
}

// MARK: - Add Track to Playlist Sheet
private struct AddToPlaylistSheet: View {
    let track: UniversalTrack
    let playlists: [UniversalPlaylist]
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("Add \"\(track.title)\" to:")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .padding(.top, 16)
                    
                    if playlists.isEmpty {
                        Text("No playlists created yet")
                            .foregroundColor(PastelTheme.textTertiary)
                    } else {
                        List {
                            ForEach(playlists) { pl in
                                Button {
                                    HapticManager.successNotification()
                                    coordinator.addTrackToPlaylist(track: track, playlistId: pl.id)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "music.note.list")
                                            .foregroundColor(PastelTheme.pastelOat)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(pl.title)
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundColor(PastelTheme.textPrimary)
                                            Text("\(pl.tracks.count) tracks")
                                                .font(.system(size: 12))
                                                .foregroundColor(PastelTheme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(PastelTheme.emeraldSuccess)
                                    }
                                }
                                .listRowBackground(PastelTheme.card)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(PastelTheme.textSecondary)
                }
            }
        }
    }
}
