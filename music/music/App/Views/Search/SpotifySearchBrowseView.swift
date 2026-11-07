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
                // Pure Pitch Black Base (#121212)
                Color(hex: "#121212")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Title
                    HStack {
                        Text("Search")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)
                    
                    // Sticky Search Bar
                    stickySearchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 14)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Top Quick-Genre Pills / Vibe Cards
                            quickGenrePillsRow
                                .padding(.bottom, 22)
                            
                            // "Browse All" Header
                            Text("Browse All")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.bottom, 12)
                            
                            // Main 2-Column Genre & Mood Grid
                            browseAllGrid
                                .padding(.bottom, 140) // Player clearance
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Sticky Search Bar (100% width, 48px, #FFFFFF, rounded-lg)
    private var stickySearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#121212"))
                .padding(.leading, 14)
            
            TextField("What do you want to listen to?", text: $searchText)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "#121212"))
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#555555"))
                        .padding(.trailing, 12)
                }
            }
        }
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
                        ZStack(alignment: .bottomLeading) {
                            Color(hex: "#1F1F1F")
                            
                            LinearGradient(
                                colors: [Color(hex: item.1).opacity(0.8), Color(hex: "#1F1F1F").opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            
                            HStack {
                                Text(item.0)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: item.2)
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .frame(width: 140, height: 44)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
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
    
    // MARK: - Main 2-Column Genre & Mood Grid ("Browse All")
    private var browseAllGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(filteredCategories) { card in
                Button {
                    HapticManager.lightImpact()
                    playGenreSelection(card)
                } label: {
                    ZStack(alignment: .topLeading) {
                        // Card Base with vibrant gradient
                        LinearGradient(
                            colors: [
                                Color(hex: card.hexColor),
                                Color(hex: card.hexColor).opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Circular Artwork Thumbnail (No black squares, 100% luminous circular vinyl rings!)
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    // Outer translucent circular disc with subtle glass sheen
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.25),
                                                    Color.white.opacity(0.08)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 66, height: 66)
                                    
                                    // Concentric Vinyl / Soundwave Rings
                                    Circle()
                                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                                        .frame(width: 52, height: 52)
                                    
                                    Circle()
                                        .stroke(Color.white.opacity(0.15), lineWidth: 0.8)
                                        .frame(width: 38, height: 38)
                                    
                                    // Center Well Ring
                                    Circle()
                                        .fill(Color.white.opacity(0.14))
                                        .frame(width: 24, height: 24)
                                    
                                    // Crisp Icon Symbol
                                    Image(systemName: card.iconSymbol)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.25), radius: 3)
                                }
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.32), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 6, y: 3)
                                .offset(x: 8, y: 4)
                            }
                        }
                        
                        // Title Typography: Positioned top-left, 16px bold 700 #FFFFFF, line-height 1.2
                        Text(card.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .padding([.top, .leading], 14)
                    }
                    .frame(height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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

