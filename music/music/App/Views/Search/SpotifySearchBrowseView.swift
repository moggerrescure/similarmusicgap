import SwiftUI

/// Genre Card Model for Spotify Browse All Grid
public struct SpotifyGenreCard: Identifiable {
    public let id: Int
    public let title: String
    public let hexColor: String
    public let iconSymbol: String
    public let queryTag: String
}

/// Pixel-perfect Spotify "Search & Browse Genres" Tab based on production specs
public struct SpotifySearchBrowseView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    @State private var searchText: String = ""
    @State private var selectedGenre: String? = nil
    @State private var browseNotice: String? = nil
    
    // Top 3 Quick-Genre Pills / Vibe Cards
    /// Broad library keywords (no personal #tags that never match).
    private let topVibeCards = [
        ("pop", "#3A2E39", "star.fill"),
        ("hip hop", "#263238", "flame.fill"),
        ("indie", "#2E3B4E", "heart.text.square.fill"),
        ("chill", "#1E3264", "cup.and.saucer.fill")
    ]
    
    private var trimmedQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var isSearching: Bool {
        !trimmedQuery.isEmpty
    }
    
    private var libraryResults: LibraryLocalSearch.Results {
        LibraryLocalSearch.search(
            query: trimmedQuery,
            tracks: coordinator.allTracks,
            playlists: coordinator.allPlaylists
        )
    }
    
    // All 32 Exact Category Cards with Specification HEX Colors
    private let genreCategories: [SpotifyGenreCard] = [
        // Honest library filters — titles match what Search actually queries (synced library keywords).
        SpotifyGenreCard(id: 1, title: "Pop", hexColor: "#E11D74", iconSymbol: "music.quarternote.3", queryTag: "pop"),
        SpotifyGenreCard(id: 2, title: "Live", hexColor: "#5B4B7A", iconSymbol: "theatermasks.fill", queryTag: "live"),
        SpotifyGenreCard(id: 3, title: "Remix", hexColor: "#477D95", iconSymbol: "arrow.triangle.2.circlepath", queryTag: "remix"),
        SpotifyGenreCard(id: 4, title: "Acoustic", hexColor: "#0D5C46", iconSymbol: "guitars.fill", queryTag: "acoustic"),
        SpotifyGenreCard(id: 5, title: "New", hexColor: "#E13300", iconSymbol: "flame.fill", queryTag: "new"),
        SpotifyGenreCard(id: 6, title: "Synth", hexColor: "#477D95", iconSymbol: "waveform", queryTag: "synth"),
        SpotifyGenreCard(id: 7, title: "Hip-Hop", hexColor: "#4B8299", iconSymbol: "headphones", queryTag: "rap"),
        SpotifyGenreCard(id: 8, title: "Game", hexColor: "#E8115B", iconSymbol: "gamecontroller.fill", queryTag: "game"),
        SpotifyGenreCard(id: 9, title: "Rock", hexColor: "#006450", iconSymbol: "guitars.fill", queryTag: "rock"),
        SpotifyGenreCard(id: 10, title: "Top", hexColor: "#8D67AB", iconSymbol: "chart.line.uptrend.xyaxis", queryTag: "top"),
        SpotifyGenreCard(id: 11, title: "Chill", hexColor: "#E1118B", iconSymbol: "face.smiling.fill", queryTag: "chill"),
        SpotifyGenreCard(id: 12, title: "EDM", hexColor: "#477D95", iconSymbol: "waveform.path.ecg", queryTag: "edm"),
        SpotifyGenreCard(id: 13, title: "Indie", hexColor: "#E91429", iconSymbol: "heart.text.square.fill", queryTag: "indie"),
        SpotifyGenreCard(id: 14, title: "Workout", hexColor: "#777777", iconSymbol: "figure.run", queryTag: "workout"),
        SpotifyGenreCard(id: 15, title: "Soul", hexColor: "#8D67AB", iconSymbol: "heart.fill", queryTag: "soul"),
        SpotifyGenreCard(id: 16, title: "Radio", hexColor: "#D8117E", iconSymbol: "antenna.radiowaves.left.and.right", queryTag: "radio"),
        SpotifyGenreCard(id: 17, title: "Fresh", hexColor: "#F50E78", iconSymbol: "lightbulb.fill", queryTag: "fresh"),
        SpotifyGenreCard(id: 18, title: "K-pop", hexColor: "#E61E2A", iconSymbol: "star.fill", queryTag: "kpop"),
        SpotifyGenreCard(id: 19, title: "Lo-fi", hexColor: "#B06239", iconSymbol: "cup.and.saucer.fill", queryTag: "lofi"),
        SpotifyGenreCard(id: 20, title: "Ambient", hexColor: "#1E3264", iconSymbol: "moon.stars.fill", queryTag: "ambient"),
        SpotifyGenreCard(id: 21, title: "Dance", hexColor: "#8D67AB", iconSymbol: "music.note", queryTag: "dance"),
        SpotifyGenreCard(id: 22, title: "Classic", hexColor: "#B02897", iconSymbol: "music.note.list", queryTag: "classic"),
        SpotifyGenreCard(id: 23, title: "Folk", hexColor: "#537AA1", iconSymbol: "leaf.fill", queryTag: "folk"),
        SpotifyGenreCard(id: 24, title: "Drive", hexColor: "#0D72EA", iconSymbol: "car.fill", queryTag: "drive"),
        SpotifyGenreCard(id: 25, title: "Punk", hexColor: "#A56752", iconSymbol: "bolt.fill", queryTag: "punk"),
        SpotifyGenreCard(id: 26, title: "R&B", hexColor: "#BA5D07", iconSymbol: "music.mic", queryTag: "rnb"),
        SpotifyGenreCard(id: 27, title: "Latin", hexColor: "#0D72EA", iconSymbol: "sun.max.fill", queryTag: "latin"),
        SpotifyGenreCard(id: 28, title: "Blues", hexColor: "#148A08", iconSymbol: "music.note", queryTag: "blues"),
        SpotifyGenreCard(id: 29, title: "Retro", hexColor: "#A56752", iconSymbol: "clock.arrow.circlepath", queryTag: "retro"),
        SpotifyGenreCard(id: 30, title: "Romance", hexColor: "#D8118B", iconSymbol: "heart.circle.fill", queryTag: "romance"),
        SpotifyGenreCard(id: 31, title: "Metal", hexColor: "#9B111E", iconSymbol: "bolt.horizontal.fill", queryTag: "metal"),
        SpotifyGenreCard(id: 32, title: "Jazz", hexColor: "#5B4B7A", iconSymbol: "pianokeys", queryTag: "jazz")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Ambient Gradient Wash (Search Tone)
                AmbientWashBackgroundView(tab: .search)
                
                VStack(spacing: 0) {
                    // Header Title
                    HStack {
                        Text("Search")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    
                    // Sticky Search Bar (Audiophile Frosted Graphite Pill)
                    stickySearchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Genre-tile notice when browsing empty/miss — skip if empty-library results already explain it.
                            if let browseNotice,
                               !(isSearching && coordinator.allTracks.isEmpty && coordinator.allPlaylists.isEmpty) {
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(PastelTheme.amberWarning)
                                    Text(browseNotice)
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(PastelTheme.amberWarning.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .padding(.bottom, 12)
                                .accessibilityLabel(browseNotice)
                            }
                            
                            if isSearching {
                                librarySearchResultsSection
                                    .padding(.bottom, 140)
                            } else {
                                // Top Quick-Genre Pills / Vibe Cards
                                quickGenrePillsRow
                                    .padding(.bottom, 20)
                                
                                // Keyword shelves over synced library (not remote genre radio)
                                HStack {
                                    Text("Browse your library")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .foregroundColor(PastelTheme.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(genreCategories.count) keywords · local only")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(PastelTheme.textTertiary)
                                }
                                .padding(.bottom, 12)
                                
                                // Main 2-Column Vinyl Crate Grid
                                browseAllGrid
                                    .padding(.bottom, 140) // Player clearance
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .onAppear { consumePendingSearchIfNeeded() }
            .onChange(of: navCoordinator.pendingSearchQuery) { _, newValue in
                if newValue != nil {
                    consumePendingSearchIfNeeded()
                }
            }
        }
    }
    
    private func consumePendingSearchIfNeeded() {
        guard let pending = navCoordinator.consumePendingSearchQuery(), !pending.isEmpty else { return }
        searchText = pending
        browseNotice = nil
    }
    
    // MARK: - Synced library results (replaces fake genre radio playback)
    @ViewBuilder
    private var librarySearchResultsSection: some View {
        let results = libraryResults
        
        if coordinator.allTracks.isEmpty && coordinator.allPlaylists.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Your library is empty")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                Text("Connect Spotify or Apple Music and Sync — Search looks through your synced tracks, not a remote catalog.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
                Button {
                    NavigationCoordinator.shared.navigateToConnect()
                } label: {
                    Text("Connect services")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textOnOat)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(PastelTheme.pastelOat)
                        .clipShape(Capsule())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 4)
            }
            .padding(.top, 8)
        } else if results.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("No matches in synced library")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                Text("Nothing in your collection matches “\(trimmedQuery)”.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
            }
            .padding(.top, 8)
        } else {
            VStack(alignment: .leading, spacing: 18) {
                if !results.artists.isEmpty {
                    resultSectionHeader("Artists", count: results.artists.count)
                    ForEach(results.artists, id: \.self) { artist in
                        Button {
                            HapticManager.lightImpact()
                            let artistTracks = coordinator.allTracks.filter {
                                $0.primaryArtist.localizedCaseInsensitiveContains(artist)
                            }
                            if let first = artistTracks.first {
                                player.play(track: first, in: artistTracks)
                                browseNotice = nil
                            }
                        } label: {
                            searchRow(
                                title: artist,
                                subtitle: "Artist in your library",
                                symbol: "person.fill"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if !results.playlists.isEmpty {
                    resultSectionHeader("Playlists", count: results.playlists.count)
                    ForEach(results.playlists) { playlist in
                        Button {
                            HapticManager.lightImpact()
                            if let first = playlist.tracks.first {
                                player.play(track: first, in: playlist.tracks)
                                browseNotice = nil
                            } else if let first = LibraryLocalSearch.firstTrack(
                                matchingTag: playlist.title,
                                in: coordinator.allTracks
                            ) {
                                player.play(track: first, in: coordinator.allTracks)
                                browseNotice = nil
                            } else {
                                browseNotice = "Playlist “\(playlist.title)” has no loaded tracks yet — open Library and sync."
                            }
                        } label: {
                            searchRow(
                                title: playlist.title,
                                subtitle: "\(playlist.trackCount) tracks · \(playlist.providerType.displayName)",
                                symbol: "music.note.list"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                if !results.tracks.isEmpty {
                    resultSectionHeader("Tracks", count: results.tracks.count)
                    ForEach(results.tracks) { track in
                        Button {
                            HapticManager.lightImpact()
                            player.play(track: track, in: results.tracks)
                            browseNotice = nil
                        } label: {
                            searchRow(
                                title: track.title,
                                subtitle: track.primaryArtist,
                                symbol: "music.note"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.top, 4)
        }
    }
    
    private func resultSectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
            Spacer()
            Text("\(count)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(PastelTheme.textTertiary)
        }
    }
    
    private func searchRow(title: String, subtitle: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(PastelTheme.cardSubtle)
                    .frame(width: 44, height: 44)
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PastelTheme.pastelOat)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "play.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(PastelTheme.textTertiary)
        }
        .padding(12)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Sticky Search Bar (Audiophile Frosted Graphite Pill)
    private var stickySearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PastelTheme.pastelOat)
                .padding(.leading, 14)
            
            TextField("Search your synced library…", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
                .tint(PastelTheme.pastelOat)
                .autocorrectionDisabled()
                .accessibilityLabel("Search your synced library")
                .accessibilityIdentifier("search.field")
                .onChange(of: searchText) { oldValue, newValue in
                    // Clear notice only on user typing — not when genre tiles set the query.
                    if newValue != oldValue, abs(newValue.count - oldValue.count) == 1 || newValue.isEmpty {
                        browseNotice = nil
                    }
                }
            
            if !searchText.isEmpty {
                Button {
                    HapticManager.lightImpact()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(PastelTheme.textTertiary)
                        .padding(.trailing, 12)
                }
            } else {
                Spacer()
                    .frame(width: 8)
            }
        }
        .frame(height: 48)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Top Quick-Genre Pills / Vibe Cards
    private var quickGenrePillsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<topVibeCards.count, id: \.self) { idx in
                    let item = topVibeCards[idx]
                    Button {
                        HapticManager.lightImpact()
                        searchText = item.0
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.0)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                                .lineLimit(1)
                            
                            Image(systemName: item.2)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(PastelTheme.textTertiary)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(PastelTheme.card)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Main 2-Column Audiophile Vinyl Crate Grid
    private var browseAllGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(genreCategories) { card in
                vinylSleeveCard(card)
            }
        }
    }
    
    // Concept 1: Collector's Vinyl Pocket Sleeve Card
    private func vinylSleeveCard(_ card: SpotifyGenreCard) -> some View {
        Button {
            HapticManager.lightImpact()
            playGenreSelection(card)
        } label: {
            VStack(spacing: 10) {
                // Miniature Vinyl Record with Grooves and Colored Center Label
                ZStack {
                    // Outer Black Vinyl Wax Platter
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#0E0F12"),
                                    Color(hex: "#1A1C22"),
                                    Color(hex: "#090A0D")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: Color.black.opacity(0.55), radius: 6, y: 3)
                    
                    // Micro Concentric Grooves
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.75)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.75)
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 0.75)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.75)
                        .frame(width: 36, height: 36)
                    
                    // Anisotropic Specular Light Sheen ("виниловый крест света")
                    AngularGradient(
                        colors: [
                            Color.clear,
                            Color.white.opacity(0.12),
                            Color.clear,
                            Color.white.opacity(0.12),
                            Color.clear
                        ],
                        center: .center
                    )
                    .frame(width: 68, height: 68)
                    .clipShape(Circle())
                    
                    // Colored Center Label Hub
                    ZStack {
                        Circle()
                            .fill(Color(hex: card.hexColor))
                            .frame(width: 28, height: 28)
                            .shadow(color: Color(hex: card.hexColor).opacity(0.4), radius: 4)
                        
                        // Center Spindle Hole
                        Circle()
                            .fill(Color(hex: "#0E0F12"))
                            .frame(width: 5, height: 5)
                            .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        
                        // Crisp Category Icon
                        Image(systemName: card.iconSymbol)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 12)
                
                // Typography & Query Tag Subtitle
                VStack(spacing: 2) {
                    Text(card.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    
                    Text("#\(card.queryTag)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(PastelTheme.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 138)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func playGenreSelection(_ card: SpotifyGenreCard) {
        // Tiles filter synced library by keyword — not a remote genre radio.
        let noticeEmpty = "Library empty — Connect & Sync before browsing “\(card.title)”."
        let noticeMiss = "No synced tracks match “\(card.title)” yet. Showing library filter for “\(card.queryTag)”."
        
        if coordinator.allTracks.isEmpty {
            searchText = card.queryTag
            DispatchQueue.main.async { browseNotice = noticeEmpty }
            return
        }
        
        if let track = LibraryLocalSearch.firstTrack(
            matchingTag: card.queryTag,
            in: coordinator.allTracks
        ) ?? LibraryLocalSearch.firstTrack(
            matchingTag: card.title,
            in: coordinator.allTracks
        ) {
            searchText = card.queryTag
            player.play(track: track, in: coordinator.allTracks)
            DispatchQueue.main.async { browseNotice = nil }
            return
        }
        
        searchText = card.queryTag
        DispatchQueue.main.async { browseNotice = noticeMiss }
    }
}

