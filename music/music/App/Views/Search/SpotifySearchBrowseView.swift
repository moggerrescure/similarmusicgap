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
    
    @State private var searchText: String = ""
    @State private var selectedGenre: String? = nil
    
    // Top 3 Quick-Genre Pills / Vibe Cards
    private let topVibeCards = [
        ("hip hop", "#3A2E39", "flame.fill"),
        ("#ukrainian trap", "#263238", "bolt.fill"),
        ("#foreign hip hop", "#2E3B4E", "waveform")
    ]
    
    // All 32 Exact Category Cards with Specification HEX Colors
    private let genreCategories: [SpotifyGenreCard] = [
        SpotifyGenreCard(id: 1, title: "Music", hexColor: "#E11D74", iconSymbol: "music.quarternote.3", queryTag: "pop"),
        SpotifyGenreCard(id: 2, title: "Live Events", hexColor: "#7B00FF", iconSymbol: "theatermasks.fill", queryTag: "live"),
        SpotifyGenreCard(id: 3, title: "Made For You", hexColor: "#8C67AB", iconSymbol: "sparkles", queryTag: "mix"),
        SpotifyGenreCard(id: 4, title: "Upcoming Releases", hexColor: "#0D5C46", iconSymbol: "calendar.badge.clock", queryTag: "upcoming"),
        SpotifyGenreCard(id: 5, title: "New Releases", hexColor: "#E13300", iconSymbol: "flame.fill", queryTag: "new"),
        SpotifyGenreCard(id: 6, title: "Pop", hexColor: "#477D95", iconSymbol: "star.fill", queryTag: "pop"),
        SpotifyGenreCard(id: 7, title: "Hip-Hop", hexColor: "#4B8299", iconSymbol: "headphones", queryTag: "rap"),
        SpotifyGenreCard(id: 8, title: "Gaming", hexColor: "#E8115B", iconSymbol: "gamecontroller.fill", queryTag: "game"),
        SpotifyGenreCard(id: 9, title: "Rock", hexColor: "#006450", iconSymbol: "guitars.fill", queryTag: "rock"),
        SpotifyGenreCard(id: 10, title: "Charts", hexColor: "#8D67AB", iconSymbol: "chart.line.uptrend.xyaxis", queryTag: "top"),
        SpotifyGenreCard(id: 11, title: "Mood", hexColor: "#E1118B", iconSymbol: "face.smiling.fill", queryTag: "chill"),
        SpotifyGenreCard(id: 12, title: "Dance/Electronic", hexColor: "#477D95", iconSymbol: "waveform.path.ecg", queryTag: "edm"),
        SpotifyGenreCard(id: 13, title: "Indie", hexColor: "#E91429", iconSymbol: "heart.text.square.fill", queryTag: "indie"),
        SpotifyGenreCard(id: 14, title: "Workout Music", hexColor: "#777777", iconSymbol: "figure.run", queryTag: "workout"),
        SpotifyGenreCard(id: 15, title: "Discover", hexColor: "#8D67AB", iconSymbol: "safari.fill", queryTag: "discover"),
        SpotifyGenreCard(id: 16, title: "Radio", hexColor: "#D8117E", iconSymbol: "antenna.radiowaves.left.and.right", queryTag: "radio"),
        SpotifyGenreCard(id: 17, title: "Fresh Finds", hexColor: "#F50E78", iconSymbol: "lightbulb.fill", queryTag: "fresh"),
        SpotifyGenreCard(id: 18, title: "K-pop", hexColor: "#E61E2A", iconSymbol: "heart.fill", queryTag: "kpop"),
        SpotifyGenreCard(id: 19, title: "Chill", hexColor: "#B06239", iconSymbol: "cup.and.saucer.fill", queryTag: "lofi"),
        SpotifyGenreCard(id: 20, title: "Sleep", hexColor: "#1E3264", iconSymbol: "moon.stars.fill", queryTag: "ambient"),
        SpotifyGenreCard(id: 21, title: "Party", hexColor: "#8D67AB", iconSymbol: "party.popper.fill", queryTag: "dance"),
        SpotifyGenreCard(id: 22, title: "Trending", hexColor: "#B02897", iconSymbol: "arrow.up.right.circle.fill", queryTag: "trending"),
        SpotifyGenreCard(id: 23, title: "At Home", hexColor: "#537AA1", iconSymbol: "house.fill", queryTag: "acoustic"),
        SpotifyGenreCard(id: 24, title: "Travel", hexColor: "#0D72EA", iconSymbol: "car.fill", queryTag: "drive"),
        SpotifyGenreCard(id: 25, title: "RADAR", hexColor: "#A56752", iconSymbol: "dot.radiowaves.left.and.right", queryTag: "radar"),
        SpotifyGenreCard(id: 26, title: "R&B", hexColor: "#BA5D07", iconSymbol: "music.mic", queryTag: "rnb"),
        SpotifyGenreCard(id: 27, title: "Latin", hexColor: "#0D72EA", iconSymbol: "sun.max.fill", queryTag: "reggaeton"),
        SpotifyGenreCard(id: 28, title: "EQUAL", hexColor: "#148A08", iconSymbol: "equal.circle.fill", queryTag: "equal"),
        SpotifyGenreCard(id: 29, title: "Decades", hexColor: "#A56752", iconSymbol: "clock.arrow.circlepath", queryTag: "retro"),
        SpotifyGenreCard(id: 30, title: "Love", hexColor: "#D8118B", iconSymbol: "heart.circle.fill", queryTag: "romance"),
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
                            // Top Quick-Genre Pills / Vibe Cards
                            quickGenrePillsRow
                                .padding(.bottom, 20)
                            
                            // "Browse Genres & Vibes" Header
                            HStack {
                                Text("Browse Genres & Vibes")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                
                                Spacer()
                                
                                Text("\(filteredCategories.count) stations")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                            .padding(.bottom, 12)
                            
                            // Main 2-Column Vinyl Crate Grid
                            browseAllGrid
                                .padding(.bottom, 140) // Player clearance
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
        }
    }
    
    // MARK: - Sticky Search Bar (Audiophile Frosted Graphite Pill)
    private var stickySearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PastelTheme.pastelOat)
                .padding(.leading, 14)
            
            TextField("Search artists, vinyls, genres...", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
                .tint(PastelTheme.pastelOat)
                .autocorrectionDisabled()
            
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
    
    // Dynamic real-time search filter for categories
    private var filteredCategories: [SpotifyGenreCard] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return genreCategories }
        return genreCategories.filter {
            $0.title.lowercased().contains(query) ||
            $0.queryTag.lowercased().contains(query)
        }
    }
    
    // MARK: - Main 2-Column Audiophile Vinyl Crate Grid
    private var browseAllGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredCategories) { card in
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
        let track = UniversalTrack(
            isrc: "GENRE-\(card.id)",
            title: "\(card.title) Radio",
            artists: ["Spotify Curated"],
            album: "\(card.title) Mix",
            durationMs: 200000,
            spotifyId: "genre_\(card.id)"
        )
        player.play(track: track)
    }
}

