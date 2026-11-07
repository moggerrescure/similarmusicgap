import SwiftUI

/// Spotify-Grade "Home" Personalized Feed Tab
/// Layout:
/// 1. Top Header Bar (Avatar + Dynamic Greeting + Filter Pills)
/// 2. Recent Shortcuts 2-Column Grid (Сетка из недавних сверху)
/// 3. Prominent Search Bar (Поисковая строка)
/// 4. Horizontal Album Carousels (Красивые карусели альбомов и релизов)
public struct SpotifyHomeFeedView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    @State private var selectedFilter: String = "All"
    @State private var showingProfileSheet: Bool = false
    @State private var searchText: String = ""
    
    // MARK: - Models
    
    public struct RecentShortcut: Identifiable {
        public let id: Int
        public let title: String
        public let artist: String
        public let isArtist: Bool
        public let isPlayingNow: Bool
        public let isLikedSongs: Bool
        public let coverHex: String
        public let initialOrSymbol: String
    }
    
    public struct AlbumCardItem: Identifiable {
        public let id: Int
        public let title: String
        public let subtitle: String
        public let badgeText: String?
        public let gradientColors: [Color]
        public let systemImage: String
        public let accentColor: Color
    }
    
    // MARK: - Data (Zero Emojis, High-Contrast Palette)
    
    private let shortcuts: [RecentShortcut] = [
        RecentShortcut(id: 1, title: "заставь меня плакать", artist: "CUPSIZE", isArtist: false, isPlayingNow: true, isLikedSongs: false, coverHex: "#2E3440", initialOrSymbol: "cloud.rain.fill"),
        RecentShortcut(id: 2, title: "Liked Songs", artist: "Favorites", isArtist: false, isPlayingNow: false, isLikedSongs: true, coverHex: "#450AF5", initialOrSymbol: "heart.fill"),
        RecentShortcut(id: 3, title: "Дора", artist: "Дора", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#D08770", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 4, title: "50 Cent", artist: "50 Cent", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#4C566A", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 5, title: "влад пиво", artist: "влад пиво", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#EBCB8B", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 6, title: "Zemfira", artist: "Zemfira", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#3B4252", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 7, title: "неуравновешеннолетние", artist: "CUPSIZE", isArtist: false, isPlayingNow: false, isLikedSongs: false, coverHex: "#BF616A", initialOrSymbol: "music.note"),
        RecentShortcut(id: 8, title: "дели на два", artist: "CUPSIZE", isArtist: false, isPlayingNow: false, isLikedSongs: false, coverHex: "#5E81AC", initialOrSymbol: "music.note.list")
    ]
    
    private let newMusicFridayItems: [AlbumCardItem] = [
        AlbumCardItem(
            id: 101,
            title: "New Music Friday",
            subtitle: "Dominic Fike, LISA, Anderson .Paak, John...",
            badgeText: "NEW MUSIC\nFRIDAY",
            gradientColors: [Color(hex: "#1E1E1E"), Color(hex: "#000000")],
            systemImage: "waveform.circle.fill",
            accentColor: Color(hex: "#1ED760")
        ),
        AlbumCardItem(
            id: 102,
            title: "Release Radar",
            subtitle: "Все новинки от артистов, на которых вы подписаны",
            badgeText: "Release Radar",
            gradientColors: [Color(hex: "#0F2027"), Color(hex: "#203A43")],
            systemImage: "sparkles",
            accentColor: Color(hex: "#A78BFA")
        ),
        AlbumCardItem(
            id: 103,
            title: "Pop Rising",
            subtitle: "Olivia Rodrigo, Billie Eilish, Sabrina Carpenter...",
            badgeText: "Pop Rising",
            gradientColors: [Color(hex: "#E11D74"), Color(hex: "#8C67AB")],
            systemImage: "music.note",
            accentColor: Color.white
        ),
        AlbumCardItem(
            id: 104,
            title: "RapCaviar",
            subtitle: "Kendrick Lamar, Metro Boomin, Future...",
            badgeText: "RapCaviar",
            gradientColors: [Color(hex: "#11998E"), Color(hex: "#38EF7D")],
            systemImage: "bolt.fill",
            accentColor: Color(hex: "#38EF7D")
        )
    ]
    
    private let pickedForYouItems: [AlbumCardItem] = [
        AlbumCardItem(
            id: 201,
            title: "Club Mix",
            subtitle: "Electronic Energy & Peak Driving",
            badgeText: nil,
            gradientColors: [Color(hex: "#FF007F"), Color(hex: "#7928CA")],
            systemImage: "globe.europe.africa.fill",
            accentColor: Color.white
        ),
        AlbumCardItem(
            id: 202,
            title: "Electronic Surge",
            subtitle: "138+ BPM High Voltage Beats",
            badgeText: nil,
            gradientColors: [Color(hex: "#006450"), Color(hex: "#0D72EA")],
            systemImage: "bolt.fill",
            accentColor: Color.white
        ),
        AlbumCardItem(
            id: 203,
            title: "Night Drive Pulse",
            subtitle: "Dark Synthwave & Atmospheric Bass",
            badgeText: nil,
            gradientColors: [Color(hex: "#BA5D07"), Color(hex: "#121212")],
            systemImage: "waveform",
            accentColor: Color.white
        ),
        AlbumCardItem(
            id: 204,
            title: "Silk Lo-Fi Flow",
            subtitle: "Chill Beats to Relax & Focus",
            badgeText: nil,
            gradientColors: [Color(hex: "#4B6CB7"), Color(hex: "#182848")],
            systemImage: "moon.stars.fill",
            accentColor: Color.white
        )
    ]
    
    private let topAlbumsItems: [AlbumCardItem] = [
        AlbumCardItem(
            id: 301,
            title: "UTOPIA",
            subtitle: "Travis Scott • 19 треков",
            badgeText: nil,
            gradientColors: [Color(hex: "#3A3D40"), Color(hex: "#181719")],
            systemImage: "opticaldisc.fill",
            accentColor: Color(hex: "#EFE3D3")
        ),
        AlbumCardItem(
            id: 302,
            title: "SOS",
            subtitle: "SZA • 23 трека",
            badgeText: nil,
            gradientColors: [Color(hex: "#1F4068"), Color(hex: "#162447")],
            systemImage: "opticaldisc.fill",
            accentColor: Color(hex: "#60A5FA")
        ),
        AlbumCardItem(
            id: 303,
            title: "GUTS",
            subtitle: "Olivia Rodrigo • 12 треков",
            badgeText: nil,
            gradientColors: [Color(hex: "#795290"), Color(hex: "#341E39")],
            systemImage: "opticaldisc.fill",
            accentColor: Color(hex: "#A78BFA")
        ),
        AlbumCardItem(
            id: 304,
            title: "SCARING THE HOES",
            subtitle: "JPEGMAFIA, Danny Brown • 14 треков",
            badgeText: nil,
            gradientColors: [Color(hex: "#C0392B"), Color(hex: "#2C3E50")],
            systemImage: "opticaldisc.fill",
            accentColor: Color(hex: "#FDE68A")
        )
    ]
    
    // Filtered shortcuts when searching
    private var filteredShortcuts: [RecentShortcut] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return shortcuts
        } else {
            return shortcuts.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.artist.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic Ambient Gradient Wash (changes on each session)
                AmbientWashBackgroundView(tab: .home)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. Top Header Bar (Avatar + Dynamic Greeting + Filter Pills)
                        topHeaderBar
                            .padding(.top, 10)
                        
                        // 2. ЦВЕТНОЙ КОЛЛЕКЦИОННЫЙ ВИНИЛ & АНИМИРОВАННЫЙ ПРОИГРЫВАТЕЛЬ
                        VinylTurntableHorizonView()
                        
                        // 3. ПОИСКОВАЯ СТРОКА ПОСЕРЕДИНЕ (Sticky Search Bar)
                        prominentSearchBar
                        
                        // 4. КРАСИВАЯ КАРУСЕЛЬ АЛЬБОМОВ 1 (New Music Friday)
                        albumCarouselSection(
                            title: "It's New Music Friday!",
                            items: newMusicFridayItems
                        )
                        
                        // 5. КРАСИВАЯ КАРУСЕЛЬ АЛЬБОМОВ 2 (Picked for you)
                        albumCarouselSection(
                            title: "Friday drops picked for you",
                            items: pickedForYouItems
                        )
                        
                        // 6. КРАСИВАЯ КАРУСЕЛЬ АЛЬБОМОВ 3 (Top Albums & Vaults)
                        albumCarouselSection(
                            title: "Top Albums",
                            items: topAlbumsItems
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Full clearance for Floating Mini Player
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
        }
    }
    
    // MARK: - 1. Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 10) {
            // User Avatar (Opens Profile Sheet)
            Button {
                HapticManager.lightImpact()
                showingProfileSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#282828"))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    
                    if let avatar = coordinator.customAvatarImage {
                        avatar
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Filter Pills (All, Music, Podcasts)
            filterPill(title: "All")
            filterPill(title: "Music")
            filterPill(title: "Podcasts")
            
            Spacer(minLength: 0)
        }
    }
    
    private func filterPill(title: String) -> some View {
        let isSelected = selectedFilter == title
        return Button {
            HapticManager.lightImpact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedFilter = title
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? PastelTheme.textOnOat : .white)
                .padding(.horizontal, 16)
                .frame(height: 32)
                .background(isSelected ? PastelTheme.pastelOat : Color(hex: "#242424"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : PastelTheme.cardBorder, lineWidth: 0.8)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 2. Сетка из недавних сверху (2x4 Recent Shortcuts Grid)
    private var recentShortcutsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            let columns = [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ]
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(filteredShortcuts) { item in
                    shortcutCard(item: item)
                }
            }
        }
    }
    
    private func shortcutCard(item: RecentShortcut) -> some View {
        Button {
            HapticManager.lightImpact()
            if item.isLikedSongs {
                navCoordinator.openPersonalLibrary()
            } else {
                playMockShortcut(item)
            }
        } label: {
            HStack(spacing: 8) {
                // Thumbnail: Liked Songs Gradient, Artist Circle, or Square Flush Cover
                if item.isLikedSongs {
                    ZStack {
                        LinearGradient(
                            colors: [Color(hex: "#450AF5"), Color(hex: "#C4EFD9")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else if item.isArtist {
                    ZStack {
                        Circle()
                            .fill(Color(hex: item.coverHex))
                            .frame(width: 42, height: 42)
                        Image(systemName: item.initialOrSymbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.leading, 5)
                } else {
                    ZStack {
                        Color(hex: item.coverHex)
                        Image(systemName: item.initialOrSymbol)
                            .font(.system(size: 19, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                
                // Track / Artist Title
                Text(item.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
                
                // Active Equalizer Indicator if currently playing
                if item.isPlayingNow || (player.isPlaying && player.currentTrack?.title == item.title) {
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "#1ED760"))
                            .frame(width: 3, height: 12)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "#1ED760"))
                            .frame(width: 3, height: 16)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "#1ED760"))
                            .frame(width: 3, height: 9)
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(height: 52)
            .background(Color(hex: "#282828"))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 3. Поисковая строка (Prominent Search Bar)
    private var prominentSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color(hex: "#121212"))
                .padding(.leading, 14)
            
            TextField("What do you want to listen to?", text: $searchText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "#121212"))
                .tint(Color(hex: "#121212"))
                .autocorrectionDisabled()
            
            if !searchText.isEmpty {
                Button {
                    HapticManager.lightImpact()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#727272"))
                        .padding(.trailing, 12)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Spacer()
                    .frame(width: 8)
            }
        }
        .frame(height: 48)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: Color.black.opacity(0.35), radius: 6, y: 2)
    }
    
    // MARK: - 4. Красивая карусель альбомов (Album Carousel Section)
    private func albumCarouselSection(title: String, items: [AlbumCardItem]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(items) { card in
                        albumCard(card: card)
                    }
                }
            }
        }
    }
    
    private func albumCard(card: AlbumCardItem) -> some View {
        Button {
            HapticManager.lightImpact()
            playMockAlbum(card)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                // Square Artwork Container (156x156)
                ZStack(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: card.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 156, height: 156)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    // Central or Top Icon
                    VStack(alignment: .leading, spacing: 0) {
                        Image(systemName: card.systemImage)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(card.accentColor)
                            .padding([.top, .leading], 12)
                        
                        Spacer()
                        
                        // Optional Badge Title (e.g. NEW MUSIC FRIDAY)
                        if let badge = card.badgeText {
                            Text(badge)
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(card.accentColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding([.bottom, .leading], 12)
                        }
                    }
                }
                .frame(width: 156, height: 156)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 8, y: 4)
                
                // Card Title
                Text(card.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(width: 156, alignment: .leading)
                
                // Card Subtitle
                Text(card.subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "#A7A7A7"))
                    .lineLimit(2)
                    .frame(width: 156, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Playback Helpers
    private func playMockShortcut(_ item: RecentShortcut) {
        let track = UniversalTrack(
            isrc: "SP-\(item.id)",
            title: item.title,
            artists: [item.artist],
            album: item.isLikedSongs ? "Favorites" : "Universal Vault",
            durationMs: 185000,
            spotifyId: "sp_\(item.id)"
        )
        player.play(track: track)
    }
    
    private func playMockAlbum(_ card: AlbumCardItem) {
        let track = UniversalTrack(
            isrc: "ALB-\(card.id)",
            title: card.title,
            artists: ["Featured Artists"],
            album: card.title,
            durationMs: 210000,
            spotifyId: "alb_\(card.id)"
        )
        player.play(track: track)
    }
}

#if DEBUG
struct SpotifyHomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyHomeFeedView()
    }
}
#endif
