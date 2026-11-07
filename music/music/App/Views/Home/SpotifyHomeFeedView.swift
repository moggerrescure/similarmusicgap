import SwiftUI

/// Pixel-perfect Spotify "Home" Personalized Feed Tab
public struct SpotifyHomeFeedView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var player = AudioPlayerManager.shared
    
    @State private var selectedFilter: String = "All"
    @State private var showingProfileSheet: Bool = false
    @State private var showingServicesSheet: Bool = false
    
    // Quick shortcut models
    private struct RecentShortcut: Identifiable {
        let id: Int
        let title: String
        let isArtist: Bool
        let isPlayingNow: Bool
        let isLikedSongs: Bool
        let coverHex: String
        let initialOrSymbol: String
    }
    
    private let shortcuts: [RecentShortcut] = [
        RecentShortcut(id: 1, title: "заставь меня плакать", isArtist: false, isPlayingNow: true, isLikedSongs: false, coverHex: "#2E3440", initialOrSymbol: "cloud.rain.fill"),
        RecentShortcut(id: 2, title: "Liked Songs", isArtist: false, isPlayingNow: false, isLikedSongs: true, coverHex: "#450AF5", initialOrSymbol: "heart.fill"),
        RecentShortcut(id: 3, title: "Дора", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#D08770", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 4, title: "50 Cent", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#4C566A", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 5, title: "влад пиво", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#EBCB8B", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 6, title: "Zemfira", isArtist: true, isPlayingNow: false, isLikedSongs: false, coverHex: "#3B4252", initialOrSymbol: "person.fill"),
        RecentShortcut(id: 7, title: "неуравновешеннолетниепесн...", isArtist: false, isPlayingNow: false, isLikedSongs: false, coverHex: "#BF616A", initialOrSymbol: "birthday.cake.fill"),
        RecentShortcut(id: 8, title: "дели на два", isArtist: false, isPlayingNow: false, isLikedSongs: false, coverHex: "#5E81AC", initialOrSymbol: "music.note.list")
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Pitch Black Base (#121212)
                Color(hex: "#121212")
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // 1. Top Filter Bar (Avatar + Pills)
                        topFilterBar
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                        
                        // 2. 2x4 Recent Shortcuts Grid
                        recentShortcutsGrid
                            .padding(.bottom, 28)
                        
                        // 3. Shelf 1: "It's New Music Friday!"
                        newMusicFridayShelf
                            .padding(.bottom, 28)
                        
                        // 4. Shelf 2: "Friday drops picked for you"
                        fridayDropsShelf
                            .padding(.bottom, 120) // Player clearance
                    }
                    .padding(.horizontal, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingProfileSheet) {
                UserProfileSheet()
            }
        }
    }
    
    // MARK: - 1. Top Filter Bar
    private var topFilterBar: some View {
        HStack(spacing: 8) {
            // User Avatar (Opens Profile Sheet)
            Button {
                HapticManager.lightImpact()
                showingProfileSheet = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#282828"))
                        .frame(width: 34, height: 34)
                    
                    if let avatar = coordinator.customAvatarImage {
                        avatar
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Filter Pill 1: "All" (Active - Spotify Green)
            Button {
                HapticManager.lightImpact()
                selectedFilter = "All"
            } label: {
                Text("All")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(selectedFilter == "All" ? .black : .white)
                    .padding(.horizontal, 18)
                    .frame(height: 34)
                    .background(selectedFilter == "All" ? Color(hex: "#1ED760") : Color(hex: "#242424"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(selectedFilter == "All" ? Color.clear : Color(hex: "#727272"), lineWidth: 0.8)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Filter Pill 2: "Music" (Inactive - Dark)
            Button {
                HapticManager.lightImpact()
                selectedFilter = "Music"
            } label: {
                Text("Music")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedFilter == "Music" ? .black : .white)
                    .padding(.horizontal, 18)
                    .frame(height: 34)
                    .background(selectedFilter == "Music" ? Color(hex: "#1ED760") : Color(hex: "#242424"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(selectedFilter == "Music" ? Color.clear : Color(hex: "#727272"), lineWidth: 0.8)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Filter Pill 3: "Podcasts"
            Button {
                HapticManager.lightImpact()
                selectedFilter = "Podcasts"
            } label: {
                Text("Podcasts")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(selectedFilter == "Podcasts" ? .black : .white)
                    .padding(.horizontal, 18)
                    .frame(height: 34)
                    .background(selectedFilter == "Podcasts" ? Color(hex: "#1ED760") : Color(hex: "#242424"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(selectedFilter == "Podcasts" ? Color.clear : Color(hex: "#727272"), lineWidth: 0.8)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
    }
    
    // MARK: - 2. 2x4 Recent Shortcuts Grid
    private var recentShortcutsGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(shortcuts) { item in
                Button {
                    HapticManager.lightImpact()
                    playMockShortcut(item)
                } label: {
                    HStack(spacing: 8) {
                        // Thumbnail: Circular for Artists, Square flush for Albums/Playlists
                        if item.isLikedSongs {
                            // Liked Songs diagonal gradient box
                            ZStack {
                                LinearGradient(
                                    colors: [Color(hex: "#450AF5"), Color(hex: "#C4EFD9")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        } else if item.isArtist {
                            // Circular artist portrait
                            ZStack {
                                Circle()
                                    .fill(Color(hex: item.coverHex))
                                    .frame(width: 44, height: 44)
                                Image(systemName: item.initialOrSymbol)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.leading, 6)
                        } else {
                            // Square flush album cover
                            ZStack {
                                Color(hex: item.coverHex)
                                Image(systemName: item.initialOrSymbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        
                        // Title
                        Text(item.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer(minLength: 0)
                        
                        // Equalizer badge if currently playing
                        if item.isPlayingNow {
                            HStack(spacing: 2) {
                                Circle().fill(Color(hex: "#1ED760")).frame(width: 4, height: 4)
                                Circle().fill(Color(hex: "#1ED760")).frame(width: 4, height: 4)
                                Circle().fill(Color(hex: "#1ED760")).frame(width: 4, height: 4)
                            }
                            .padding(.trailing, 8)
                        }
                    }
                    .frame(height: 56)
                    .background(Color(hex: "#282828"))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - 3. Shelf: "It's New Music Friday!"
    private var newMusicFridayShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("It's New Music Friday!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    // Card 1: New Music Friday
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [Color(hex: "#1E1E1E"), Color(hex: "#000000")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: 156, height: 156)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#1ED760"))
                                    .padding([.top, .leading], 10)
                                
                                Spacer()
                                
                                Text("NEW MUSIC\nFRIDAY")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(Color(hex: "#1ED760"))
                                    .padding([.bottom, .leading], 10)
                            }
                        }
                        .frame(width: 156, height: 156)
                        
                        Text("Dominic Fike, LISA, Anderson .Paak, John...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "#A7A7A7"))
                            .lineLimit(2)
                            .frame(width: 156, alignment: .leading)
                    }
                    
                    // Card 2: Release Radar
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [Color(hex: "#0F2027"), Color(hex: "#203A43")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: 156, height: 156)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding([.top, .leading], 10)
                                
                                Spacer()
                                
                                Text("Release Radar")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(Color(hex: "#A78BFA"))
                                    .padding([.bottom, .leading], 10)
                            }
                        }
                        .frame(width: 156, height: 156)
                        
                        Text("Catch all the latest music from artists you follow,...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "#A7A7A7"))
                            .lineLimit(2)
                            .frame(width: 156, alignment: .leading)
                    }
                    
                    // Card 3: Pop Rising
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .bottomLeading) {
                            LinearGradient(
                                colors: [Color(hex: "#E11D74"), Color(hex: "#8C67AB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: 156, height: 156)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            
                            VStack(alignment: .leading, spacing: 0) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding([.top, .leading], 10)
                                
                                Spacer()
                                
                                Text("Pop Rising")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding([.bottom, .leading], 10)
                            }
                        }
                        .frame(width: 156, height: 156)
                        
                        Text("Olivia Rodrigo, Billie Eilish, Sabrina Carpenter...")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(Color(hex: "#A7A7A7"))
                            .lineLimit(2)
                            .frame(width: 156, alignment: .leading)
                    }
                }
            }
        }
    }
    
    // MARK: - 4. Shelf: "Friday drops picked for you"
    private var fridayDropsShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Friday drops picked for you")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    // Item 1: Club Mix
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(hex: "#FF007F"), Color(hex: "#7928CA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 156, height: 156)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Text("Club Mix • Electronic Energy")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    // Item 2: Electronic Surge
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(hex: "#006450"), Color(hex: "#0D72EA")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 38))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 156, height: 156)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Text("Electronic Surge")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    // Item 3: Alternative Pulse
                    VStack(alignment: .leading, spacing: 6) {
                        ZStack {
                            LinearGradient(
                                colors: [Color(hex: "#BA5D07"), Color(hex: "#121212")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            Image(systemName: "waveform")
                                .font(.system(size: 38))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .frame(width: 156, height: 156)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        
                        Text("Alternative Pulse")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
    
    private func playMockShortcut(_ item: RecentShortcut) {
        let track = UniversalTrack(
            isrc: "SP-\(item.id)",
            title: item.title,
            artists: [item.isArtist ? item.title : "CUPSIZE"],
            album: item.isLikedSongs ? "Favorites" : "Universal Vault",
            durationMs: 185000,
            spotifyId: "sp_\(item.id)"
        )
        player.play(track: track)
    }
}
