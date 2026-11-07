import SwiftUI
import Combine

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
    @State private var selectedVaultAlbum: VaultAlbumItem? = nil
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
    
    public struct CassetteItem: Identifiable {
        public let id: Int
        public let title: String
        public let subtitle: String
        public let sideText: String
        public let tapeType: String
        public let tapeLength: String
        public let labelGradient: [Color]
        public let accentColor: Color
        public let trackIsrc: String
    }
    
    public struct VaultAlbumItem: Identifiable, Equatable {
        public let id: Int
        public let title: String
        public let artist: String
        public let releaseYear: String
        public let genre: String
        public let trackCount: String
        public let totalDuration: String
        public let gradientColors: [Color]
        public let accentColor: Color
        public let tracks: [UniversalTrack]
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
    
    private let cassetteDrops: [CassetteItem] = [
        CassetteItem(
            id: 201,
            title: "Night Drive Pulse",
            subtitle: "Dark Synthwave • 44:20",
            sideText: "SIDE A",
            tapeType: "TYPE II • HIGH BIAS",
            tapeLength: "60 MIN",
            labelGradient: [Color(hex: "#C2410C"), Color(hex: "#7C2D12")],
            accentColor: Color(hex: "#F97316"),
            trackIsrc: "TAPE-201"
        ),
        CassetteItem(
            id: 202,
            title: "Silk Lo-Fi Flow",
            subtitle: "Chill Focus Beats • 38:15",
            sideText: "SIDE A",
            tapeType: "CHROME CrO2",
            tapeLength: "45 MIN",
            labelGradient: [Color(hex: "#4338CA"), Color(hex: "#312E81")],
            accentColor: Color(hex: "#818CF8"),
            trackIsrc: "TAPE-202"
        ),
        CassetteItem(
            id: 203,
            title: "Tokyo Drift Phonk",
            subtitle: "Drift Wave & Cowbell • 52:10",
            sideText: "SIDE A",
            tapeType: "METAL TAPE IV",
            tapeLength: "60 MIN",
            labelGradient: [Color(hex: "#065F46"), Color(hex: "#022C22")],
            accentColor: Color(hex: "#10B981"),
            trackIsrc: "TAPE-203"
        ),
        CassetteItem(
            id: 204,
            title: "Club Mix Surge",
            subtitle: "138+ BPM Peak Beats • 64:00",
            sideText: "SIDE A",
            tapeType: "TYPE I • NORMAL",
            tapeLength: "90 MIN",
            labelGradient: [Color(hex: "#831843"), Color(hex: "#500724")],
            accentColor: Color(hex: "#F43F5E"),
            trackIsrc: "TAPE-204"
        )
    ]
    
    // MARK: - Album Master Tracklists
    private static let utopiaTracks: [UniversalTrack] = [
        UniversalTrack(title: "HYAENA", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 222000, spotifyId: "utopia_1"),
        UniversalTrack(title: "THANK GOD", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 184000, spotifyId: "utopia_2"),
        UniversalTrack(title: "MODERN JAM", artists: ["Travis Scott", "Teezo Touchdown"], album: "UTOPIA", durationMs: 255000, spotifyId: "utopia_3"),
        UniversalTrack(title: "MY EYES", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 251000, spotifyId: "utopia_4"),
        UniversalTrack(title: "GOD'S COUNTRY", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 127000, spotifyId: "utopia_5"),
        UniversalTrack(title: "SIRENS", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 204000, spotifyId: "utopia_6"),
        UniversalTrack(title: "MELTDOWN", artists: ["Travis Scott", "Drake"], album: "UTOPIA", durationMs: 246000, spotifyId: "utopia_7"),
        UniversalTrack(title: "FE!N", artists: ["Travis Scott", "Playboi Carti"], album: "UTOPIA", durationMs: 191000, spotifyId: "utopia_8"),
        UniversalTrack(title: "DELRESTO (ECHOES)", artists: ["Travis Scott", "Beyonce"], album: "UTOPIA", durationMs: 274000, spotifyId: "utopia_9"),
        UniversalTrack(title: "I KNOW ?", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 211000, spotifyId: "utopia_10")
    ]
    
    private static let sosTracks: [UniversalTrack] = [
        UniversalTrack(title: "SOS", artists: ["SZA"], album: "SOS", durationMs: 117000, spotifyId: "sos_1"),
        UniversalTrack(title: "Kill Bill", artists: ["SZA"], album: "SOS", durationMs: 153000, spotifyId: "sos_2"),
        UniversalTrack(title: "Seek & Destroy", artists: ["SZA"], album: "SOS", durationMs: 203000, spotifyId: "sos_3"),
        UniversalTrack(title: "Low", artists: ["SZA"], album: "SOS", durationMs: 181000, spotifyId: "sos_4"),
        UniversalTrack(title: "Love Language", artists: ["SZA"], album: "SOS", durationMs: 183000, spotifyId: "sos_5"),
        UniversalTrack(title: "Blind", artists: ["SZA"], album: "SOS", durationMs: 150000, spotifyId: "sos_6"),
        UniversalTrack(title: "Snooze", artists: ["SZA"], album: "SOS", durationMs: 201000, spotifyId: "sos_7"),
        UniversalTrack(title: "Notice Me", artists: ["SZA"], album: "SOS", durationMs: 160000, spotifyId: "sos_8"),
        UniversalTrack(title: "Gone Girl", artists: ["SZA"], album: "SOS", durationMs: 244000, spotifyId: "sos_9"),
        UniversalTrack(title: "Ghost in the Machine", artists: ["SZA", "Phoebe Bridgers"], album: "SOS", durationMs: 218000, spotifyId: "sos_10")
    ]
    
    private static let gutsTracks: [UniversalTrack] = [
        UniversalTrack(title: "all-american bitch", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 165000, spotifyId: "guts_1"),
        UniversalTrack(title: "bad idea right?", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 184000, spotifyId: "guts_2"),
        UniversalTrack(title: "vampire", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 219000, spotifyId: "guts_3"),
        UniversalTrack(title: "lacy", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 177000, spotifyId: "guts_4"),
        UniversalTrack(title: "ballad of a homeschooled girl", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 203000, spotifyId: "guts_5"),
        UniversalTrack(title: "making the bed", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 198000, spotifyId: "guts_6"),
        UniversalTrack(title: "logical", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 231000, spotifyId: "guts_7"),
        UniversalTrack(title: "get him back!", artists: ["Olivia Rodrigo"], album: "GUTS", durationMs: 211000, spotifyId: "guts_8")
    ]
    
    private static let scaringTracks: [UniversalTrack] = [
        UniversalTrack(title: "Lean Beef Patty", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 107000, spotifyId: "scaring_1"),
        UniversalTrack(title: "Steppa Pig", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 207000, spotifyId: "scaring_2"),
        UniversalTrack(title: "SCARING THE HOES", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 142000, spotifyId: "scaring_3"),
        UniversalTrack(title: "Garbage Pale Kids", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 164000, spotifyId: "scaring_4"),
        UniversalTrack(title: "Fentanyl Tester", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 156000, spotifyId: "scaring_5"),
        UniversalTrack(title: "Burfict!", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 138000, spotifyId: "scaring_6"),
        UniversalTrack(title: "Shut Yo Bitch Ass Up", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 166000, spotifyId: "scaring_7"),
        UniversalTrack(title: "Kingdom Hearts Key", artists: ["JPEGMAFIA", "Danny Brown"], album: "SCARING THE HOES", durationMs: 203000, spotifyId: "scaring_8")
    ]
    
    private let vaultAlbums: [VaultAlbumItem] = [
        VaultAlbumItem(
            id: 301,
            title: "UTOPIA",
            artist: "Travis Scott",
            releaseYear: "2023",
            genre: "Hip-Hop / Trap",
            trackCount: "19 tracks",
            totalDuration: "1 hr 13 min",
            gradientColors: [Color(hex: "#2F3136"), Color(hex: "#141518")],
            accentColor: Color(hex: "#EFE3D3"),
            tracks: utopiaTracks
        ),
        VaultAlbumItem(
            id: 302,
            title: "SOS",
            artist: "SZA",
            releaseYear: "2022",
            genre: "R&B / Soul",
            trackCount: "23 tracks",
            totalDuration: "1 hr 8 min",
            gradientColors: [Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
            accentColor: Color(hex: "#60A5FA"),
            tracks: sosTracks
        ),
        VaultAlbumItem(
            id: 303,
            title: "GUTS",
            artist: "Olivia Rodrigo",
            releaseYear: "2023",
            genre: "Alt-Pop / Rock",
            trackCount: "12 tracks",
            totalDuration: "39 min",
            gradientColors: [Color(hex: "#6B21A8"), Color(hex: "#2E1065")],
            accentColor: Color(hex: "#A78BFA"),
            tracks: gutsTracks
        ),
        VaultAlbumItem(
            id: 304,
            title: "SCARING THE HOES",
            artist: "JPEGMAFIA, Danny Brown",
            releaseYear: "2023",
            genre: "Experimental Hip-Hop",
            trackCount: "14 tracks",
            totalDuration: "36 min",
            gradientColors: [Color(hex: "#991B1B"), Color(hex: "#1E293B")],
            accentColor: Color(hex: "#FDE68A"),
            tracks: scaringTracks
        )
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
                        
                        // 4. HERO RELEASE SLEEVE (Vinyl Disc Initially Protruding + Rotating)
                        heroVinylSleeveSection
                        
                        // 5. AUTHENTIC COMPACT CASSETTES (Picked for You - Authentic Philips Tape Decks)
                        cassetteTapesSection
                        
                        // 6. TOP VAULT ALBUMS (Vinyl Crate Shelf with Peeking Discs)
                        topAlbumsCrateSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Full clearance for Floating Mini Player
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
            .sheet(item: $selectedVaultAlbum) { album in
                VaultAlbumDetailSheet(album: album)
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
    
    // MARK: - 4. Hero Release Sleeve (Vinyl Disc Initially Protruding)
    private var isHeroPlaying: Bool {
        player.isPlaying && player.currentTrack?.isrc == "DROP-NMF-2024"
    }
    
    private var heroVinylSleeveSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("HERO DROP OF THE WEEK")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
                
                Text("VINYL SLEEVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PastelTheme.warmAmber)
            }
            
            // Hero Sleeve Card
            Button {
                HapticManager.lightImpact()
                toggleHeroPlayback()
            } label: {
                HStack(spacing: 16) {
                    // Left: Sleeve Case with initially protruding vinyl disc
                    ZStack(alignment: .leading) {
                        // 1. Vinyl Record - INITIALLY PROTRUDING BY 52pt (High-Visibility Collector Wax)
                        ProtrudingVinylDiscView(
                            isPlaying: isHeroPlaying,
                            diameter: 124
                        )
                        .offset(x: 52)
                        .shadow(color: Color.black.opacity(0.85), radius: 14, x: 10, y: 5)
                        
                        // 2. Sleeve Jacket (Covers left part of disc)
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#25272F"), Color(hex: "#131418")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 116, height: 116)
                            
                            // Subtle texture and border
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                .frame(width: 116, height: 116)
                            
                            // Sleeve Mouth Drop Shadow (adds realistic physical depth on the protruding disc)
                            HStack {
                                Spacer()
                                LinearGradient(
                                    colors: [Color.black.opacity(0.85), Color.clear],
                                    startPoint: .trailing,
                                    endPoint: .leading
                                )
                                .frame(width: 16, height: 116)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            .frame(width: 116, height: 116)
                            
                            // Cover Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NEW MUSIC\nFRIDAY")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.white)
                                    .lineSpacing(1)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(PastelTheme.emeraldSuccess)
                                        .frame(width: 4, height: 4)
                                    Text("FLAC 24-BIT")
                                        .font(.system(size: 8, weight: .black))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                            }
                            .padding(10)
                            .frame(width: 116, height: 116, alignment: .topLeading)
                        }
                    }
                    .frame(width: 178, height: 124)
                    
                    // Right: Information & Capsule Action
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(PastelTheme.warmAmber)
                                .frame(width: 6, height: 6)
                            Text("NEW DROP")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(PastelTheme.warmAmber)
                        }
                        
                        Text("New Music Friday")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Dominic Fike, LISA, Anderson .Paak, John Summit")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .lineLimit(2)
                            .lineSpacing(2)
                        
                        Spacer(minLength: 4)
                        
                        // Oat Capsule CTA
                        HStack(spacing: 6) {
                            Image(systemName: isHeroPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text(isHeroPlaying ? "Pause Drop" : "Play Drop")
                                .font(.system(size: 11, weight: .heavy))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(PastelTheme.pastelOat)
                        .clipShape(Capsule())
                        .shadow(color: PastelTheme.pastelOat.opacity(0.2), radius: 6, y: 2)
                    }
                    .frame(maxHeight: 114)
                }
                .padding(14)
                .background(PastelTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isHeroPlaying ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - 5. Authentic Compact Cassettes (Picked For You)
    private var cassetteTapesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FRIDAY DROPS PICKED FOR YOU")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
                
                Text("CASSETTE DECK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PastelTheme.warmAmber)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(cassetteDrops) { drop in
                        let isPlaying = player.isPlaying && player.currentTrack?.isrc == drop.trackIsrc
                        CassetteTapeCard(
                            item: drop,
                            isPlaying: isPlaying,
                            onTogglePlay: {
                                HapticManager.lightImpact()
                                toggleCassettePlayback(drop)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 6. Top Albums Crate Shelf (Vinyl Records Floating Out)
    private var topAlbumsCrateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP VAULT ALBUMS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
                
                Text("VINYL CRATE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(PastelTheme.slateBlue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(vaultAlbums) { album in
                        let isPlaying = player.isPlaying && (player.currentTrack?.album == album.title || album.tracks.contains(where: { $0.id == player.currentTrack?.id }))
                        VaultAlbumCrateCard(
                            album: album,
                            isPlaying: isPlaying,
                            onOpenAlbum: {
                                HapticManager.lightImpact()
                                selectedVaultAlbum = album
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Playback Helpers
    private func toggleHeroPlayback() {
        if isHeroPlaying {
            player.togglePlayPause()
        } else {
            let track = UniversalTrack(
                isrc: "DROP-NMF-2024",
                title: "New Music Friday",
                artists: ["Dominic Fike", "LISA", "Anderson .Paak"],
                album: "Friday Vault Drop",
                durationMs: 204000,
                spotifyId: "hero_nmf_2024"
            )
            player.play(track: track)
        }
    }
    
    private func toggleCassettePlayback(_ item: CassetteItem) {
        if player.isPlaying && player.currentTrack?.isrc == item.trackIsrc {
            player.togglePlayPause()
        } else {
            let track = UniversalTrack(
                isrc: item.trackIsrc,
                title: item.title,
                artists: ["Cassette Vault Masters"],
                album: item.title,
                durationMs: 198000,
                spotifyId: "tape_\(item.id)"
            )
            player.play(track: track)
        }
    }
    
    private func toggleVaultAlbumPlayback(_ album: VaultAlbumItem) {
        if player.isPlaying && player.currentTrack?.title == album.title {
            player.togglePlayPause()
        } else {
            let track = UniversalTrack(
                isrc: "VAULT-\(album.id)",
                title: album.title,
                artists: [album.artist],
                album: album.title,
                durationMs: 215000,
                spotifyId: "vault_\(album.id)"
            )
            player.play(track: track)
        }
    }
    
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
}

// MARK: - Supporting Components

/// Motion Tracker for analog audio rotating mechanisms
private final class AnalogRotationTracker: ObservableObject {
    @Published var tick: Bool = false
    var accumulatedTime: Double = 0.0
    var lastDate: Date? = nil
    
    func advance(currentDate: Date, isPlaying: Bool) -> Double {
        guard isPlaying else {
            lastDate = nil
            return accumulatedTime
        }
        
        if let last = lastDate {
            let delta = currentDate.timeIntervalSince(last)
            if delta > 0 && delta < 0.5 {
                accumulatedTime += delta
            }
        }
        lastDate = currentDate
        return accumulatedTime
    }
}

/// Protruding Vinyl Record that peaks out of the sleeve initially by default
/// High-fidelity black wax, 6 micro-groove tracks, butterfly specular sheen,
/// dead wax run-out zone, and rich collector amber/gold label with micro-typography
public struct ProtrudingVinylDiscView: View {
    let isPlaying: Bool
    let diameter: CGFloat
    
    @StateObject private var motionTracker = AnalogRotationTracker()
    
    public var body: some View {
        TimelineView(.animation(paused: !isPlaying)) { timeline in
            let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
            let rotation = (playTime.truncatingRemainder(dividingBy: 3.0) / 3.0) * 360.0
            
            ZStack {
                // 1. Deep Carbon Base Wax with outer lip
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "#1A1B22"), Color(hex: "#08090C")],
                            center: .center,
                            startRadius: 8,
                            endRadius: diameter / 2
                        )
                    )
                    .frame(width: diameter, height: diameter)
                
                // Outer Lip Stroke
                Circle()
                    .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    .frame(width: diameter, height: diameter)
                
                // 2. High-Fidelity Micro-Grooves (Concentric sound tracks)
                ForEach(0..<6) { i in
                    let insets: [CGFloat] = [7, 14, 21, 28, 34, 40]
                    let opacities: [Double] = [0.08, 0.05, 0.09, 0.04, 0.07, 0.05]
                    let inset = insets[i]
                    let op = opacities[i]
                    Circle()
                        .stroke(Color.white.opacity(op), lineWidth: 0.9)
                        .frame(width: max(0, diameter - (inset * 2)), height: max(0, diameter - (inset * 2)))
                }
                
                // 3. Dead Wax / Run-out Groove Zone (between tracks and label)
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 2)
                    .frame(width: max(0, diameter - 88), height: max(0, diameter - 88))
                
                // 4. Dual Butterfly Specular Sheen (Vinyl Light Reflection Flares)
                Circle()
                    .fill(
                        AngularGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.18), location: 0.10),
                                .init(color: Color.clear, location: 0.22),
                                .init(color: Color.white.opacity(0.18), location: 0.35),
                                .init(color: Color.clear, location: 0.48),
                                .init(color: Color.white.opacity(0.18), location: 0.60),
                                .init(color: Color.clear, location: 0.72),
                                .init(color: Color.white.opacity(0.18), location: 0.85),
                                .init(color: Color.clear, location: 0.98)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: diameter, height: diameter)
                    .blendMode(.plusLighter)
                
                // 5. Collector Amber/Gold Center Label (38pt)
                ZStack {
                    // Multi-Tone Amber Radial Gradient
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#FEF08A"),
                                    Color(hex: "#FBBF24"),
                                    Color(hex: "#D97706"),
                                    Color(hex: "#78350F")
                                ],
                                center: .center,
                                startRadius: 4,
                                endRadius: 20
                            )
                        )
                        .frame(width: 38, height: 38)
                    
                    // Dark Inner Groove Ring
                    Circle()
                        .stroke(Color(hex: "#0E0F12"), lineWidth: 1.8)
                        .frame(width: 38, height: 38)
                    
                    // Printed Label Typography
                    VStack(spacing: 0.5) {
                        Text("SOUNDSHIFT")
                            .font(.system(size: 4.5, weight: .black, design: .monospaced))
                            .foregroundColor(Color(hex: "#0E0F12"))
                        
                        HStack(spacing: 5) {
                            Text("33⅓")
                                .font(.system(size: 3.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#0E0F12"))
                            Text("STEREO")
                                .font(.system(size: 3.5, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(hex: "#0E0F12"))
                        }
                        
                        Text("DROP 45")
                            .font(.system(size: 3.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(Color(hex: "#0E0F12"))
                    }
                    
                    // Metallic Spindle Grommet
                    Circle()
                        .stroke(Color(hex: "#E5E7EB"), lineWidth: 1.2)
                        .frame(width: 8, height: 8)
                    
                    // Spindle Hole
                    Circle()
                        .fill(Color(hex: "#090A0D"))
                        .frame(width: 6.5, height: 6.5)
                }
            }
            .rotationEffect(.degrees(rotation))
        }
    }
}

/// Authentic Philips Compact Cassette Card
public struct CassetteTapeCard: View {
    let item: SpotifyHomeFeedView.CassetteItem
    let isPlaying: Bool
    let onTogglePlay: () -> Void
    
    @StateObject private var motionTracker = AnalogRotationTracker()
    
    public var body: some View {
        Button(action: onTogglePlay) {
            VStack(alignment: .leading, spacing: 10) {
                // Cassette Chassis (178 x 112)
                TimelineView(.animation(paused: !isPlaying)) { timeline in
                    let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
                    let spoolAngle = (playTime.truncatingRemainder(dividingBy: 2.4) / 2.4) * 360.0
                    
                    ZStack(alignment: .top) {
                        // 1. Dark Polymer Shell Base
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "#16171B"))
                            .frame(width: 178, height: 112)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(isPlaying ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 1)
                            )
                        
                        // 2. Four Corner Screws (Cross-head metallic rivets)
                        VStack {
                            HStack {
                                screwView
                                Spacer()
                                screwView
                            }
                            Spacer()
                            HStack {
                                screwView
                                Spacer()
                                screwView
                            }
                        }
                        .padding(5)
                        .frame(width: 178, height: 112)
                        
                        // 3. Cassette Contents (Label + Clear Window + Bottom Head Wedge)
                        VStack(spacing: 4) {
                            // Top Vintage Label Strip
                            VStack(spacing: 2) {
                                HStack {
                                    Text(item.sideText)
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.85))
                                    Spacer()
                                    Text(item.tapeLength)
                                        .font(.system(size: 7, weight: .black, design: .monospaced))
                                        .foregroundColor(Color.white.opacity(0.85))
                                }
                                
                                Text(item.title.uppercased())
                                    .font(.system(size: 9.5, weight: .heavy))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text(item.tapeType)
                                    .font(.system(size: 6.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.white.opacity(0.7))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(width: 162, height: 38)
                            .background(
                                LinearGradient(
                                    colors: item.labelGradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                            
                            // Central Clear Acrylic Inspection Window
                            ZStack {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color(hex: "#090A0D"))
                                    .frame(width: 136, height: 36)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                                
                                // Tape Ribbon connecting spools at bottom of window
                                VStack {
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(hex: "#381A0F"))
                                        .frame(width: 128, height: 3)
                                }
                                .frame(width: 136, height: 36)
                                
                                HStack(spacing: 12) {
                                    // Left Spool (Fuller Tape Roll)
                                    CassetteSpoolView(
                                        tapeDiameter: 26,
                                        rotationAngle: spoolAngle
                                    )
                                    
                                    // Central Counter & Scale Index
                                    VStack(spacing: 2) {
                                        Text("100   50   0")
                                            .font(.system(size: 5.5, weight: .black, design: .monospaced))
                                            .foregroundColor(Color.white.opacity(0.45))
                                        
                                        HStack(spacing: 3) {
                                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 6)
                                            Rectangle().fill(Color.white.opacity(0.5)).frame(width: 1, height: 8)
                                            Rectangle().fill(Color.white.opacity(0.3)).frame(width: 1, height: 6)
                                        }
                                    }
                                    .frame(width: 38)
                                    
                                    // Right Spool (Thinner Tape Roll)
                                    CassetteSpoolView(
                                        tapeDiameter: 20,
                                        rotationAngle: spoolAngle
                                    )
                                }
                            }
                            
                            // Bottom Tape-Head Trapezoid Wedge
                            ZStack {
                                CassetteBottomWedgeShape()
                                    .fill(Color(hex: "#101115"))
                                    .frame(width: 144, height: 18)
                                    .overlay(
                                        CassetteBottomWedgeShape()
                                            .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
                                    )
                                
                                HStack(spacing: 14) {
                                    // Left Capstan Hole
                                    Circle()
                                        .fill(Color(hex: "#060709"))
                                        .frame(width: 4.5, height: 4.5)
                                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                                    
                                    // Center Tape Head Opening Slot
                                    ZStack {
                                        Rectangle()
                                            .fill(Color(hex: "#060709"))
                                            .frame(width: 32, height: 6)
                                            .cornerRadius(1)
                                        
                                        // Magnetic tape strip
                                        Rectangle()
                                            .fill(Color(hex: "#3D2014"))
                                            .frame(width: 32, height: 2.5)
                                        
                                        // Brass Pressure Pad Spring
                                        RoundedRectangle(cornerRadius: 0.5)
                                            .fill(Color(hex: "#D97706"))
                                            .frame(width: 4.5, height: 3)
                                    }
                                    
                                    // Right Capstan Hole
                                    Circle()
                                        .fill(Color(hex: "#060709"))
                                        .frame(width: 4.5, height: 4.5)
                                        .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .frame(width: 178, height: 112)
                .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
                
                // Track Titles & Subtitles Below Cassette
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if isPlaying {
                            // Active Playing Equalizer indicator
                            HStack(spacing: 1.5) {
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 8)
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 12)
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 6)
                            }
                        }
                    }
                    
                    Text(item.subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .lineLimit(1)
                }
                .frame(width: 178, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var screwView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#50535C"))
                .frame(width: 4.5, height: 4.5)
            Rectangle()
                .fill(Color(hex: "#1A1B20"))
                .frame(width: 2.8, height: 0.6)
            Rectangle()
                .fill(Color(hex: "#1A1B20"))
                .frame(width: 0.6, height: 2.8)
        }
    }
}

/// Cassette Dual Spool with internal 6-tooth gear drive and magnetic oxide tape
public struct CassetteSpoolView: View {
    let tapeDiameter: CGFloat
    let rotationAngle: Double
    
    public var body: some View {
        ZStack {
            // Magnetic oxide tape pack
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#3D2014"), Color(hex: "#22110B")],
                        center: .center,
                        startRadius: 7,
                        endRadius: max(8, tapeDiameter / 2)
                    )
                )
                .frame(width: tapeDiameter, height: tapeDiameter)
            
            // White plastic hub ring
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 1.8)
                .background(Circle().fill(Color(hex: "#101115")))
                .frame(width: 17, height: 17)
            
            // 6 radial gear teeth / cogs
            ZStack {
                ForEach(0..<6) { i in
                    RoundedRectangle(cornerRadius: 0.5)
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 2, height: 5)
                        .offset(y: -5)
                        .rotationEffect(.degrees(Double(i) * 60))
                }
                
                // Spindle drive hole
                Circle()
                    .fill(Color(hex: "#07080A"))
                    .frame(width: 6.5, height: 6.5)
            }
            .rotationEffect(.degrees(rotationAngle))
        }
    }
}

/// Bottom Tape-Head Trapezoid Wedge Shape
public struct CassetteBottomWedgeShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let taper: CGFloat = rect.width * 0.08
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width - taper, y: rect.height))
        path.addLine(to: CGPoint(x: taper, y: rect.height))
        path.closeSubpath()
        return path
    }
}

/// Top Vault Album Crate Card with Rotating Vinyl Disc and Modal Album Sheet Trigger
public struct VaultAlbumCrateCard: View {
    let album: SpotifyHomeFeedView.VaultAlbumItem
    let isPlaying: Bool
    let onOpenAlbum: () -> Void
    
    @StateObject private var motionTracker = AnalogRotationTracker()
    
    public var body: some View {
        Button(action: onOpenAlbum) {
            VStack(alignment: .leading, spacing: 8) {
                // Jacket + Peeking Disc Container (126x100)
                ZStack(alignment: .leading) {
                    // Rotating Vinyl disc peeking out to the right by 26pt!
                    TimelineView(.animation(paused: !isPlaying)) { timeline in
                        let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
                        let rotation = (playTime.truncatingRemainder(dividingBy: 3.0) / 3.0) * 360.0
                        
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(hex: "#1F2026"), Color(hex: "#090A0D")],
                                        center: .center,
                                        startRadius: 4,
                                        endRadius: 48
                                    )
                                )
                                .frame(width: 96, height: 96)
                            
                            // Sound Grooves
                            ForEach(0..<3) { i in
                                Circle()
                                    .stroke(Color.white.opacity(0.06), lineWidth: 0.8)
                                    .frame(width: CGFloat(96 - (14 + i * 16)), height: CGFloat(96 - (14 + i * 16)))
                            }
                            
                            // Specular angular sheen
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [
                                            Color.white.opacity(0.12),
                                            Color.clear,
                                            Color.white.opacity(0.12),
                                            Color.clear,
                                            Color.white.opacity(0.12)
                                        ],
                                        center: .center
                                    )
                                )
                                .frame(width: 96, height: 96)
                                .blendMode(.plusLighter)
                            
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                                .frame(width: 96, height: 96)
                            
                            // Center Label with album accent color
                            ZStack {
                                Circle()
                                    .fill(album.accentColor.opacity(0.85))
                                    .frame(width: 26, height: 26)
                                
                                Circle()
                                    .stroke(Color(hex: "#0E0F12"), lineWidth: 1.5)
                                    .frame(width: 26, height: 26)
                                
                                Circle()
                                    .fill(Color(hex: "#0E0F12"))
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .rotationEffect(.degrees(rotation))
                    }
                    .offset(x: 26)
                    .shadow(color: Color.black.opacity(0.65), radius: 8, x: 5, y: 3)
                    
                    // Album Jacket Sleeve
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: album.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 98, height: 98)
                        
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isPlaying ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 1)
                            .frame(width: 98, height: 98)
                        
                        // Mouth gradient shadow
                        HStack {
                            Spacer()
                            LinearGradient(
                                colors: [Color.black.opacity(0.75), Color.clear],
                                startPoint: .trailing,
                                endPoint: .leading
                            )
                            .frame(width: 12, height: 98)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                        .frame(width: 98, height: 98)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(album.title)
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Text(album.artist)
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Color.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .padding(8)
                    }
                    .frame(width: 98, height: 98)
                }
                .frame(width: 126, height: 100)
                
                // Titles below
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(album.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if isPlaying {
                            HStack(spacing: 1.5) {
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 8)
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 11)
                                RoundedRectangle(cornerRadius: 0.5)
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 2, height: 6)
                            }
                        }
                    }
                    
                    Text("\(album.artist) • \(album.trackCount)")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .lineLimit(1)
                }
                .frame(width: 126, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#if DEBUG
struct SpotifyHomeFeedView_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyHomeFeedView()
    }
}
#endif
