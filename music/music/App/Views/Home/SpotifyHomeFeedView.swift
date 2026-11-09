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
    @State private var selectedCassetteTape: CassetteItem? = nil
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
        public let symbolOrInitial: String
        public let releaseYear: String
        public let genre: String
        public let trackCount: String
        public let totalDuration: String
        public let gradientColors: [Color]
        public let waxGradient: [Color]
        public let labelGradient: [Color]
        public let labelTextColor: Color
        public let glowColor: Color
        public let accentColor: Color
        public let tracks: [UniversalTrack]
    }
    
    public struct VIPArtistPassItem: Identifiable {
        public let id: Int
        public let rank: String
        public let name: String
        public let photoGradient: [Color]
        public let streamsText: String
        public let affinityText: String
        public let leadTrack: UniversalTrack
    }
    
    public struct SoundStripReleaseItem: Identifiable {
        public let id: Int
        public let title: String
        public let artists: String
        public let badgeText: String
        public let tagText: String
        public let coverGradient: [Color]
        public let symbolIcon: String
        public let leadTrack: UniversalTrack
    }
    
    public struct SmokedGlassVibeItem: Identifiable {
        public let id: Int
        public let title: String
        public let subtitle: String
        public let moodBadge: String
        public let countsText: String
        public let auraColor: Color
        public let leadTrack: UniversalTrack
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
            symbolOrInitial: "TS",
            releaseYear: "2023",
            genre: "Hip-Hop / Trap",
            trackCount: "19 tracks",
            totalDuration: "1 hr 13 min",
            gradientColors: [Color(hex: "#2F3136"), Color(hex: "#141518")],
            waxGradient: [Color(hex: "#4B5563"), Color(hex: "#1F2937"), Color(hex: "#111827")],
            labelGradient: [Color(hex: "#EFE3D3"), Color(hex: "#D1D5DB")],
            labelTextColor: Color(hex: "#0E0F12"),
            glowColor: Color(hex: "#EFE3D3"),
            accentColor: Color(hex: "#EFE3D3"),
            tracks: utopiaTracks
        ),
        VaultAlbumItem(
            id: 302,
            title: "SOS",
            artist: "SZA",
            symbolOrInitial: "SZA",
            releaseYear: "2022",
            genre: "R&B / Soul",
            trackCount: "23 tracks",
            totalDuration: "1 hr 8 min",
            gradientColors: [Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
            waxGradient: [Color(hex: "#2563EB"), Color(hex: "#1D4ED8"), Color(hex: "#0F172A")],
            labelGradient: [Color(hex: "#60A5FA"), Color(hex: "#2563EB")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#60A5FA"),
            accentColor: Color(hex: "#60A5FA"),
            tracks: sosTracks
        ),
        VaultAlbumItem(
            id: 303,
            title: "GUTS",
            artist: "Olivia Rodrigo",
            symbolOrInitial: "OR",
            releaseYear: "2023",
            genre: "Alt-Pop / Rock",
            trackCount: "12 tracks",
            totalDuration: "39 min",
            gradientColors: [Color(hex: "#6B21A8"), Color(hex: "#2E1065")],
            waxGradient: [Color(hex: "#9333EA"), Color(hex: "#6B21A8"), Color(hex: "#2E1065")],
            labelGradient: [Color(hex: "#C084FC"), Color(hex: "#7E22CE")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#C084FC"),
            accentColor: Color(hex: "#A78BFA"),
            tracks: gutsTracks
        ),
        VaultAlbumItem(
            id: 304,
            title: "SCARING THE HOES",
            artist: "JPEGMAFIA, Danny Brown",
            symbolOrInitial: "SH",
            releaseYear: "2023",
            genre: "Experimental Hip-Hop",
            trackCount: "14 tracks",
            totalDuration: "36 min",
            gradientColors: [Color(hex: "#991B1B"), Color(hex: "#1E293B")],
            waxGradient: [Color(hex: "#DC2626"), Color(hex: "#991B1B"), Color(hex: "#2B0B0B")],
            labelGradient: [Color(hex: "#F87171"), Color(hex: "#B91C1C")],
            labelTextColor: Color.white,
            glowColor: Color(hex: "#EF4444"),
            accentColor: Color(hex: "#FDE68A"),
            tracks: scaringTracks
        )
    ]
    
    private let topArtistPasses: [VIPArtistPassItem] = [
        VIPArtistPassItem(
            id: 401,
            rank: "#1",
            name: "Travis Scott",
            photoGradient: [Color(hex: "#1E1B4B"), Color(hex: "#0F0E2A")],
            streamsText: "342M streams",
            affinityText: "99% match",
            leadTrack: UniversalTrack(title: "MY EYES", artists: ["Travis Scott"], album: "UTOPIA", durationMs: 251000, spotifyId: "art_401")
        ),
        VIPArtistPassItem(
            id: 402,
            rank: "#2",
            name: "SZA",
            photoGradient: [Color(hex: "#1E3A8A"), Color(hex: "#0F172A")],
            streamsText: "285M streams",
            affinityText: "98% match",
            leadTrack: UniversalTrack(title: "Snooze", artists: ["SZA"], album: "SOS", durationMs: 201000, spotifyId: "art_402")
        ),
        VIPArtistPassItem(
            id: 403,
            rank: "#3",
            name: "Playboi Carti",
            photoGradient: [Color(hex: "#4A0E17"), Color(hex: "#1A0508")],
            streamsText: "210M streams",
            affinityText: "96% match",
            leadTrack: UniversalTrack(title: "2024", artists: ["Playboi Carti"], album: "MUSIC", durationMs: 165000, spotifyId: "art_403")
        ),
        VIPArtistPassItem(
            id: 404,
            rank: "#4",
            name: "Kendrick Lamar",
            photoGradient: [Color(hex: "#78350F"), Color(hex: "#292524")],
            streamsText: "194M streams",
            affinityText: "95% match",
            leadTrack: UniversalTrack(title: "Not Like Us", artists: ["Kendrick Lamar"], album: "GNX", durationMs: 274000, spotifyId: "art_404")
        ),
        VIPArtistPassItem(
            id: 405,
            rank: "#5",
            name: "Дора",
            photoGradient: [Color(hex: "#BE185D"), Color(hex: "#500724")],
            streamsText: "140M streams",
            affinityText: "94% match",
            leadTrack: UniversalTrack(title: "Втюрилась", artists: ["Дора"], album: "Боже, храни кьют-рок", durationMs: 148000, spotifyId: "art_405")
        )
    ]
    
    private let soundStripReleases: [SoundStripReleaseItem] = [
        SoundStripReleaseItem(
            id: 501,
            title: "Ruby Rosary",
            artists: "A$AP Rocky, J. Cole",
            badgeText: "TODAY",
            tagText: "SINGLE",
            coverGradient: [Color(hex: "#7F1D1D"), Color(hex: "#1C0505")],
            symbolIcon: "sparkles",
            leadTrack: UniversalTrack(title: "Ruby Rosary", artists: ["A$AP Rocky", "J. Cole"], album: "Don't Be Dumb", durationMs: 215000, spotifyId: "rel_501")
        ),
        SoundStripReleaseItem(
            id: 502,
            title: "CHROMAKOPIA",
            artists: "Tyler, The Creator",
            badgeText: "2D AGO",
            tagText: "ALBUM • 14 TRACKS",
            coverGradient: [Color(hex: "#14532D"), Color(hex: "#052E16")],
            symbolIcon: "theatermasks.fill",
            leadTrack: UniversalTrack(title: "St. Chroma", artists: ["Tyler, The Creator", "Daniel Caesar"], album: "CHROMAKOPIA", durationMs: 197000, spotifyId: "rel_502")
        ),
        SoundStripReleaseItem(
            id: 503,
            title: "Brat (Remix)",
            artists: "Charli xcx, Billie Eilish",
            badgeText: "THIS WEEK",
            tagText: "DELUXE",
            coverGradient: [Color(hex: "#65A30D"), Color(hex: "#1A2E05")],
            symbolIcon: "bolt.fill",
            leadTrack: UniversalTrack(title: "Guess feat. Billie Eilish", artists: ["Charli xcx", "Billie Eilish"], album: "Brat and it's completely different", durationMs: 178000, spotifyId: "rel_503")
        )
    ]
    
    private let smokedGlassVibes: [SmokedGlassVibeItem] = [
        SmokedGlassVibeItem(
            id: 601,
            title: "Midnight Velocity",
            subtitle: "Dark Synthwave & Heavy 808",
            moodBadge: "LATE NIGHT 432Hz",
            countsText: "32 tracks • 1 hr 54m",
            auraColor: Color(hex: "#4338CA"),
            leadTrack: UniversalTrack(title: "Night Drive Pulse", artists: ["Kavinsky", "HOME"], album: "Midnight Velocity", durationMs: 230000, spotifyId: "vibe_601")
        ),
        SmokedGlassVibeItem(
            id: 602,
            title: "Sub-Bass Coliseum",
            subtitle: "Travis Scott, Carti, Metro",
            moodBadge: "HEAVY BASS 808",
            countsText: "28 tracks • 1 hr 35m",
            auraColor: Color(hex: "#DC2626"),
            leadTrack: UniversalTrack(title: "FE!N", artists: ["Travis Scott", "Playboi Carti"], album: "Sub-Bass Coliseum", durationMs: 191000, spotifyId: "vibe_602")
        ),
        SmokedGlassVibeItem(
            id: 603,
            title: "Morning Warm Wax",
            subtitle: "Rhodes, Warm Vinyl, Soul",
            moodBadge: "ANALOG WARMTH",
            countsText: "26 tracks • 1 hr 22m",
            auraColor: Color(hex: "#F59E0B"),
            leadTrack: UniversalTrack(title: "Morning Warm Wax", artists: ["Nujabes", "Saib"], album: "Analog Coffee", durationMs: 210000, spotifyId: "vibe_603")
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
            ZStack(alignment: .top) {
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
                        
                        // 7. TOP ARTISTS (VIP Backstage Pass Lanyards)
                        topArtistsLanyardSection
                        
                        // 8. FRESH RELEASES (Interactive SoundStrip Samplers)
                        freshReleasesSoundStripsSection
                        
                        // 9. CURATED MIXES (Smoked Glass Vibe Tiles)
                        curatedMixesVibeTilesSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 120) // Full clearance for Floating Mini Player
                }
                
                // TOP-DOWN ALBUM VAULT (SLIDES DOWN FROM TOP OF PHONE SCREEN)
                if let album = selectedVaultAlbum {
                    VaultAlbumTopDownView(album: album) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                            selectedVaultAlbum = nil
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(100)
                }
                
                // TOP-DOWN CASSETTE MIXTAPE RADIO (SLIDES DOWN FROM TOP OF PHONE SCREEN)
                if let tape = selectedCassetteTape {
                    CassetteRadioDetailView(tape: tape) {
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                            selectedCassetteTape = nil
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(101)
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
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
                HStack(spacing: 14) {
                    // Left: Sleeve Case with initially protruding vinyl disc (guaranteed zero overlap with text)
                    ZStack(alignment: .leading) {
                        // 1. Vinyl Record - INITIALLY PROTRUDING BY 32pt (Never overlaps letters)
                        ProtrudingVinylDiscView(
                            isPlaying: isHeroPlaying,
                            diameter: 104
                        )
                        .offset(x: 32)
                        .shadow(color: Color.black.opacity(0.85), radius: 10, x: 6, y: 3)
                        
                        // 2. Sleeve Jacket (Covers left part of disc)
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#25272F"), Color(hex: "#131418")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 104, height: 104)
                            
                            // Subtle texture and border
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                .frame(width: 104, height: 104)
                            
                            // Sleeve Mouth Drop Shadow (adds realistic physical depth on the protruding disc)
                            HStack {
                                Spacer()
                                LinearGradient(
                                    colors: [Color.black.opacity(0.85), Color.clear],
                                    startPoint: .trailing,
                                    endPoint: .leading
                                )
                                .frame(width: 14, height: 104)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                            .frame(width: 104, height: 104)
                            
                            // Cover Content
                            VStack(alignment: .leading, spacing: 3) {
                                Text("NEW MUSIC\nFRIDAY")
                                    .font(.system(size: 11.5, weight: .black))
                                    .foregroundColor(.white)
                                    .lineSpacing(1)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(PastelTheme.emeraldSuccess)
                                        .frame(width: 4, height: 4)
                                    Text("FLAC 24-BIT")
                                        .font(.system(size: 7.5, weight: .black))
                                        .foregroundColor(Color(hex: "#9CA3AF"))
                                }
                            }
                            .padding(8)
                            .frame(width: 104, height: 104, alignment: .topLeading)
                        }
                    }
                    .frame(width: 138, height: 106)
                    
                    // Right: Information & Capsule Action (Completely clear of disc)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(PastelTheme.warmAmber)
                                .frame(width: 6, height: 6)
                            Text("NEW DROP")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(PastelTheme.warmAmber)
                        }
                        
                        Text("New Music Friday")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Dominic Fike, LISA, Anderson .Paak, John Summit")
                            .font(.system(size: 11.5, weight: .regular))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .lineLimit(2)
                            .lineSpacing(2)
                        
                        Spacer(minLength: 2)
                        
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(maxHeight: 106)
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
                Text("FRIDAY DROPS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
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
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                    selectedCassetteTape = drop
                                }
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
                Text("TOP ALBUMS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
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
                                withAnimation(.spring(response: 0.38, dampingFraction: 0.85)) {
                                    selectedVaultAlbum = album
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 7. Top Artists (VIP Backstage Pass Lanyards)
    private var topArtistsLanyardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("TOP ARTISTS")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(topArtistPasses) { pass in
                        let isPlaying = player.isPlaying && player.currentTrack?.title == pass.leadTrack.title
                        VIPArtistPassCard(
                            pass: pass,
                            isPlaying: isPlaying,
                            onPlay: {
                                HapticManager.lightImpact()
                                player.play(track: pass.leadTrack)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 8. Fresh Releases (Interactive SoundStrip Samplers)
    private var freshReleasesSoundStripsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FRESH RELEASES")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(soundStripReleases) { release in
                        let isPlaying = player.isPlaying && player.currentTrack?.title == release.leadTrack.title
                        SoundStripReleaseCard(
                            item: release,
                            isPlaying: isPlaying,
                            onPlay: {
                                HapticManager.lightImpact()
                                player.play(track: release.leadTrack)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 9. Curated Mixes (Smoked Glass Vibe Tiles)
    private var curatedMixesVibeTilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CURATED MIXES")
                    .font(.system(size: 11, weight: .heavy))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: "#9CA3AF"))
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(smokedGlassVibes) { vibe in
                        let isPlaying = player.isPlaying && player.currentTrack?.title == vibe.leadTrack.title
                        SmokedGlassVibeCard(
                            item: vibe,
                            isPlaying: isPlaying,
                            onPlay: {
                                HapticManager.lightImpact()
                                player.play(track: vibe.leadTrack)
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
                    // Collector's Edition Rotating Marbled Vinyl Disc (peeking out by 28pt)
                    TimelineView(.animation(paused: !isPlaying)) { timeline in
                        let playTime = motionTracker.advance(currentDate: timeline.date, isPlaying: isPlaying)
                        let rotation = (playTime.truncatingRemainder(dividingBy: 3.5) / 3.5) * 360.0
                        
                        ZStack {
                            // 1. Marbled Colored Wax Base
                            Circle()
                                .fill(
                                    AngularGradient(
                                        colors: [
                                            album.waxGradient.first ?? Color(hex: "#2E1A22"),
                                            album.waxGradient.last ?? Color(hex: "#0E070A"),
                                            album.waxGradient.first?.opacity(0.7) ?? Color(hex: "#2E1A22"),
                                            album.waxGradient.first?.opacity(0.95) ?? Color(hex: "#450A0A"),
                                            Color.white.opacity(0.18),
                                            album.waxGradient.last?.opacity(0.85) ?? Color(hex: "#0E070A"),
                                            album.waxGradient.first ?? Color(hex: "#2E1A22")
                                        ],
                                        center: .center
                                    )
                                )
                                .frame(width: 94, height: 94)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.20), lineWidth: 1.0)
                                )
                                .shadow(color: album.glowColor.opacity(isPlaying ? 0.55 : 0.25), radius: isPlaying ? 10 : 5)
                            
                            // 2. Physical Concentric Micro-Grooves
                            Circle().stroke(Color.white.opacity(0.09), lineWidth: 0.75).frame(width: 84, height: 84)
                            Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.75).frame(width: 74, height: 74)
                            Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.75).frame(width: 64, height: 64)
                            Circle().stroke(Color.white.opacity(0.07), lineWidth: 0.75).frame(width: 54, height: 54)
                            
                            // 3. Anisotropic Specular Light Sheen ("Виниловый крест света")
                            AngularGradient(
                                colors: [
                                    Color.clear,
                                    Color.white.opacity(0.18),
                                    Color.clear,
                                    Color.white.opacity(0.18),
                                    Color.clear
                                ],
                                center: .center
                            )
                            .clipShape(Circle())
                            
                            // 4. Deluxe Center Paper Label with Rotating Two-Tone Art & Micro-Typography
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: album.labelGradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                    .overlay(Circle().stroke(Color.black.opacity(0.6), lineWidth: 1.2))
                                
                                // Two-tone semi-circle arc for high-contrast visible rotation tracking
                                Circle()
                                    .trim(from: 0.0, to: 0.5)
                                    .fill(Color.black.opacity(0.25))
                                    .frame(width: 30, height: 30)
                                
                                // Micro-Typography
                                VStack(spacing: 6) {
                                    Text("SIDE A")
                                        .font(.system(size: 4.0, weight: .black, design: .monospaced))
                                        .foregroundColor(album.labelTextColor.opacity(0.85))
                                    Text("33 ⅓")
                                        .font(.system(size: 3.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(album.labelTextColor.opacity(0.75))
                                }
                                
                                // Center Artist Initial / SF Symbol
                                Text(album.symbolOrInitial)
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundColor(album.labelTextColor)
                                
                                // Spindle Hole
                                Circle()
                                    .fill(Color(hex: "#090A0D"))
                                    .frame(width: 5.5, height: 5.5)
                            }
                        }
                        .rotationEffect(.degrees(rotation))
                    }
                    .offset(x: 28)
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

// MARK: - 7. VIP Backstage Pass Card
public struct VIPArtistPassCard: View {
    public let pass: SpotifyHomeFeedView.VIPArtistPassItem
    public let isPlaying: Bool
    public let onPlay: () -> Void
    
    public var body: some View {
        Button(action: onPlay) {
            ZStack(alignment: .top) {
                // Background Photo / Gradient
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: pass.photoGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 118, height: 168)
                
                // Dark Scrim for text readability
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.85)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(width: 118, height: 168)
                
                // Hologram Foil Diagonal Sheen
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.12), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .frame(width: 118, height: 168)
                
                // Outer Border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isPlaying ? PastelTheme.athleticEmerald : PastelTheme.cardBorder, lineWidth: 1)
                    .frame(width: 118, height: 168)
                
                // Lanyard Clasp Assembly at Top
                VStack(spacing: 0) {
                    // Strap Tab
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "#1A1B22"))
                        .frame(width: 28, height: 10)
                        .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        .offset(y: -4)
                    
                    // Metal Chrome Grommet Clamp
                    ZStack {
                        Capsule()
                            .fill(LinearGradient(colors: [Color(hex: "#E5E7EB"), Color(hex: "#6B7280")], startPoint: .top, endPoint: .bottom))
                            .frame(width: 32, height: 8)
                        Circle()
                            .fill(Color(hex: "#0E0F12"))
                            .frame(width: 4, height: 4)
                    }
                    .offset(y: -2)
                }
                
                // Card Inner Contents
                VStack(alignment: .leading, spacing: 0) {
                    // Top Rank Pill (#1, #2, etc.)
                    HStack {
                        Text(pass.rank)
                            .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.warmAmber)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PastelTheme.warmAmber.opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(PastelTheme.warmAmber.opacity(0.4), lineWidth: 0.8))
                        
                        Spacer()
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 8)
                    
                    Spacer()
                    
                    // Bottom Artist Name & Streams
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pass.name)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(pass.streamsText)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .lineLimit(1)
                        
                        HStack {
                            Text(pass.affinityText)
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(PastelTheme.athleticEmerald)
                            
                            Spacer()
                            
                            // Play Circle
                            ZStack {
                                Circle()
                                    .fill(isPlaying ? PastelTheme.athleticEmerald : PastelTheme.pastelOat)
                                    .frame(width: 22, height: 22)
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(isPlaying ? .white : PastelTheme.textOnOat)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
                }
                .frame(width: 118, height: 168)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 8. Interactive SoundStrip Release Card
public struct SoundStripReleaseCard: View {
    public let item: SpotifyHomeFeedView.SoundStripReleaseItem
    public let isPlaying: Bool
    public let onPlay: () -> Void
    
    public var body: some View {
        Button(action: onPlay) {
            HStack(spacing: 12) {
                // Left: Square Cover Art
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: item.coverGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 84, height: 84)
                    
                    Image(systemName: item.symbolIcon)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 84, height: 84)
                    
                    // Badge (TODAY, THIS WEEK)
                    Text(item.badgeText)
                        .font(.system(size: 7, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(PastelTheme.athleticEmerald)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                        .padding(5)
                }
                .frame(width: 84, height: 84)
                
                // Right: Information & Mini Waveform Bar
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.tagText)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(PastelTheme.warmAmber)
                    
                    Text(item.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(item.artists)
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                        .lineLimit(1)
                    
                    Spacer(minLength: 2)
                    
                    // Mini Player Bar
                    HStack(spacing: 6) {
                        Text(item.leadTrack.title)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if isPlaying {
                            WaveformBarsView(color: PastelTheme.athleticEmerald, isAnimating: true)
                                .frame(width: 14, height: 10)
                        }
                        
                        // Mini Play Circle
                        ZStack {
                            Circle()
                                .fill(PastelTheme.pastelOat)
                                .frame(width: 18, height: 18)
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(PastelTheme.textOnOat)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 84)
            }
            .padding(10)
            .frame(width: 236, height: 104)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isPlaying ? PastelTheme.athleticEmerald : PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 9. Smoked Glass Vibe Card
public struct SmokedGlassVibeCard: View {
    public let item: SpotifyHomeFeedView.SmokedGlassVibeItem
    public let isPlaying: Bool
    public let onPlay: () -> Void
    
    public var body: some View {
        Button(action: onPlay) {
            ZStack(alignment: .topLeading) {
                // Smoked Glass Surface
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: "#17181D").opacity(0.95))
                    .frame(width: 160, height: 108)
                
                // Mood Aura Glow in top right corner
                Circle()
                    .fill(item.auraColor.opacity(0.45))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .offset(x: 90, y: -20)
                
                // Border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isPlaying ? PastelTheme.slateBlue : PastelTheme.cardBorder, lineWidth: 1)
                    .frame(width: 160, height: 108)
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    // Mood Badge
                    Text(item.moodBadge)
                        .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(PastelTheme.pastelOat)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                    
                    Spacer()
                    
                    // Title & Subtitle
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(item.subtitle)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .lineLimit(1)
                    }
                    
                    // Footer: Counts & VU Meter
                    HStack {
                        Text(item.countsText)
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#6B7280"))
                        
                        Spacer()
                        
                        // Animated VU Bars
                        HStack(spacing: 2) {
                            ForEach(0..<4) { i in
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(PastelTheme.slateBlue)
                                    .frame(width: 2.5, height: isPlaying ? CGFloat([6, 11, 4, 9][i]) : 3)
                            }
                        }
                    }
                }
                .padding(10)
                .frame(width: 160, height: 108, alignment: .leading)
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
