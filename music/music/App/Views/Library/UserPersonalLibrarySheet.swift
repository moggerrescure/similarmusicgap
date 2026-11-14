import SwiftUI

/// Top-level library filter categories
public enum LibrarySegment: String, CaseIterable, Identifiable {
    case tracks = "Tracks"
    case playlists = "Playlists"
    case favorites = "Saved"
    case duplicates = "Duplicates"
    
    public var id: String { rawValue }
}

/// Synced Library sheet — tracks/playlists from LIVE services + local SoundShift bookmarks.
/// Contains all personal tracks, playlists, favorites, duplicates, and custom orderings.
public struct UserPersonalLibrarySheet: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText: String = ""
    // Synced collection shortcut opens synced tracks (local ♥ bookmarks may be empty).
    @State private var selectedSegment: LibrarySegment = .tracks
    @State private var selectedProviderFilter: MusicProviderType? = nil
    
    // Sheets
    @State private var showingDuplicatesSheet: Bool = false
    @State private var showingCreatePlaylistSheet: Bool = false
    @State private var selectedPlaylistForDetail: UniversalPlaylist? = nil
    @State private var trackForAddToPlaylist: UniversalTrack? = nil
    
    // Reorder state
    @State private var isReordering: Bool = false
    @State private var liftedTrackId: UUID? = nil
    @State private var customOrderedTracks: [UniversalTrack] = []
    
    private var baseTracks: [UniversalTrack] {
        coordinator.allTracks
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
        coordinator.allPlaylists
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
                // Dynamic Ambient Gradient Wash
                AmbientWashBackgroundView()
                
                VStack(spacing: 0) {
                    // Search Bar
                    searchBar
                    
                    // Segments
                    segmentBar
                    
                    // Provider Chips
                    if selectedSegment != .playlists {
                        providerFilterStrip
                    }
                    
                    // Reorder Mode Active Banner
                    if isReordering {
                        reorderBanner
                    }
                    
                    // Main Content
                    if selectedSegment == .playlists {
                        playlistsContentView
                    } else {
                        tracksContentView
                    }
                }
            }
            .navigationTitle(MigratorChrome.syncedLibraryTitle)
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        HapticManager.lightImpact()
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(PastelTheme.pastelOat)
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if selectedSegment == .playlists {
                        Button {
                            HapticManager.lightImpact()
                            showingCreatePlaylistSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                    } else {
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
                PersonalLibraryAddToPlaylistSheet(track: track, playlists: playlists)
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
        .padding(.top, 8)
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
                                .stroke(isSel ? Color.clear : PastelTheme.marbleBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.0))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Provider Filter Strip
    private var providerFilterStrip: some View {
        HStack(spacing: 8) {
            ForEach(MusicProviderType.availableConnectors) { provider in
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isSel ? Color(hex: provider.brandColorHex).opacity(0.18) : PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(isSel ? Color(hex: provider.brandColorHex).opacity(0.5) : PastelTheme.marbleBorder, lineWidth: 1)
                    )
                }
                .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.0))
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
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Tracks Content
    @ViewBuilder
    private var tracksContentView: some View {
        if filteredTracks.isEmpty {
            VStack(spacing: 14) {
                Spacer()
                Image(systemName: "music.note.list")
                    .font(.system(size: 38))
                    .foregroundColor(PastelTheme.textTertiary)
                Text(
                    coordinator.allTracks.isEmpty
                        ? "Library is empty"
                        : (selectedSegment == .favorites
                           ? "No SoundShift bookmarks yet — synced service tracks are under Tracks"
                           : "No tracks match filters")
                )
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(PastelTheme.textSecondary)
                if coordinator.allTracks.isEmpty {
                    Text("Connect Spotify or Apple Music, then Sync — demo tracks are gone.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(PastelTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Button {
                        dismiss()
                        NavigationCoordinator.shared.navigateToConnect()
                    } label: {
                        Text("Connect services")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textOnOat)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                }
                Spacer()
            }
        } else {
            List {
                ForEach(filteredTracks) { track in
                    personalTrackRow(for: track)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .listRowSeparator(.hidden)
                }
                .onMove(perform: moveTracks)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            #if os(iOS)
            .environment(\.editMode, isReordering ? .constant(.active) : .constant(.inactive))
            #endif
            .padding(.bottom, 30)
        }
    }
    
    @ViewBuilder
    private func personalTrackRow(for track: UniversalTrack) -> some View {
        let isCurr = player.currentTrack == track
        let isPlaying = isCurr && player.isPlaying
        let isFav = player.isFavorite(track: track)
        let isLifted = liftedTrackId == track.id
        
        PersonalLibraryTrackRow(
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
        // Indices come from filteredTracks — map to full customOrderedTracks by id.
        if customOrderedTracks.isEmpty {
            customOrderedTracks = allTracks
        }
        let visible = filteredTracks
        let movingIds = source.compactMap { idx -> UUID? in
            guard visible.indices.contains(idx) else { return nil }
            return visible[idx].id
        }
        guard !movingIds.isEmpty else { return }
        
        var working = customOrderedTracks
        let fromOffsets = IndexSet(movingIds.compactMap { id in working.firstIndex(where: { $0.id == id }) })
        guard !fromOffsets.isEmpty else { return }
        
        // Destination: index among full list of the item currently at `destination` in filtered view
        let destId: UUID? = {
            if destination < visible.count { return visible[destination].id }
            return nil
        }()
        let toOffset: Int = {
            if let destId, let idx = working.firstIndex(where: { $0.id == destId }) {
                return idx
            }
            return working.count
        }()
        
        working.move(fromOffsets: fromOffsets, toOffset: toOffset)
        customOrderedTracks = working
        if coordinator.allTracks.count == customOrderedTracks.count {
            coordinator.reorderTracks(fromOffsets: fromOffsets, toOffset: toOffset)
        }
        HapticManager.lightImpact()
    }
}

// MARK: - Row Component
private struct PersonalLibraryTrackRow: View {
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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
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
                
                // Trailing Action Area (All icons strictly aligned on the same horizontal level across every song)
                HStack(spacing: 8) {
                    // 1. Provider Brand Badges (Vertically centered at height 32)
                    HStack(spacing: 4) {
                        if track.spotifyId != nil {
                            PlatformBrandBadgeView(type: .spotify, size: 14)
                        }
                        if track.appleMusicId != nil {
                            PlatformBrandBadgeView(type: .appleMusic, size: 14)
                        }
                        if YandexMusicProvider.isConnectorEnabled, track.yandexId != nil {
                            PlatformBrandBadgeView(type: .yandexMusic, size: 14)
                        }
                    }
                    .frame(height: 32, alignment: .trailing)
                    
                    // 2. Trailing Action: Reorder drag handle OR Ellipsis Menu (Fixed 32x32 frame, vertically centered)
                    if isReordering {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(PastelTheme.textTertiary)
                            .frame(width: 32, height: 32, alignment: .center)
                    } else {
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
                                Label(
                                    isFavorite ? "Remove \(MigratorChrome.localSavedAccessibility)" : MigratorChrome.localSavedAccessibility,
                                    systemImage: isFavorite ? "heart.slash" : "heart"
                                )
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
                }
                .frame(height: 32, alignment: .center)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                isLifted
                    ? PastelTheme.cardSubtle
                    : (isCurrent ? PastelTheme.pastelOat.opacity(0.08) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: isCurrent || isLifted ? 12 : 0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isLifted ? PastelTheme.amberWarning : (isCurrent ? PastelTheme.marbleBorder : Color.clear), lineWidth: 1)
            )
            .shadow(color: isLifted ? PastelTheme.amberWarning.opacity(0.3) : Color.clear, radius: 10, y: 4)
            
            if !isLifted {
                Rectangle()
                    .fill(Color(hex: "#F5F5F7").opacity(0.06))
                    .frame(height: 0.5)
                    .padding(.leading, 68)
            }
        }
    }
}

// MARK: - Add Track to Playlist Sheet
private struct PersonalLibraryAddToPlaylistSheet: View {
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
