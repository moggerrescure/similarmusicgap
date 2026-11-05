import SwiftUI

/// Luxury Apple HIG HUD Modal to create a custom playlist with track selection
public struct CreatePlaylistSheet: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var descriptionText: String = ""
    @State private var selectedTrackIds: Set<UUID> = []
    @State private var searchTrackText: String = ""
    @State private var selectedThemeIndex: Int = 0
    
    // Preset cover gradient themes
    private let themes: [(name: String, colors: [Color])] = [
        ("Aurora Emerald", [PastelTheme.emeraldSuccess, Color(hex: "#065F46")]),
        ("Solar Amber", [Color(hex: "#F59E0B"), Color(hex: "#78350F")]),
        ("Rose Liquid", [Color(hex: "#FB7185"), Color(hex: "#831843")]),
        ("Midnight Slate", [Color(hex: "#60A5FA"), Color(hex: "#1E3A8A")]),
        ("Oat Cashmere", [PastelTheme.pastelOat, Color(hex: "#27272A")])
    ]
    
    private var availableTracks: [UniversalTrack] {
        let list = coordinator.allTracks.isEmpty ? [
            UniversalTrack(isrc: "USUM71703861", title: "Starboy", artists: ["The Weeknd", "Daft Punk"], album: "Starboy", durationMs: 230453, yandexId: "29871638", spotifyId: "7a26vX02Y4vYj9P6RrqU04"),
            UniversalTrack(isrc: "GBUM71505080", title: "The Less I Know the Better", artists: ["Tame Impala"], album: "Currents", durationMs: 216320, spotifyId: "6K4t31amVTKVgPeRoxXErq"),
            UniversalTrack(isrc: "USAT21900122", title: "Blinding Lights", artists: ["The Weeknd"], album: "After Hours", durationMs: 200040, appleMusicId: "1499378607"),
            UniversalTrack(isrc: "RUAA12000042", title: "Где нас нет", artists: ["Oxxxymiron"], album: "ГОРГОРОД", durationMs: 265000, yandexId: "24981120"),
            UniversalTrack(isrc: "FRUM71300088", title: "Instant Crush", artists: ["Daft Punk", "Julian Casablancas"], album: "Random Access Memories", durationMs: 337560, yandexId: "14589231", spotifyId: "2bpgKp31sOVoTeStOXzi8C"),
            UniversalTrack(isrc: "USWB11200021", title: "Midnight City", artists: ["M83"], album: "Hurry Up, We're Dreaming", durationMs: 243000, spotifyId: "1eyzqe2QqGZUmfcPZtrIyt", appleMusicId: "466487841")
        ] : coordinator.allTracks
        
        if searchTrackText.isEmpty {
            return list
        }
        let q = searchTrackText.lowercased()
        return list.filter {
            $0.title.lowercased().contains(q) ||
            $0.primaryArtist.lowercased().contains(q)
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Live Artwork Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: themes[selectedThemeIndex].colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 130, height: 130)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(PastelTheme.cardBorderFocused, lineWidth: 1)
                                )
                                .shadow(color: themes[selectedThemeIndex].colors.first!.opacity(0.35), radius: 16, y: 6)
                            
                            VStack(spacing: 6) {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(PastelTheme.textOnOat)
                                
                                Text("\(selectedTrackIds.count) tracks")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textOnOat.opacity(0.85))
                            }
                        }
                        .padding(.top, 10)
                        
                        // MARK: - Theme Color Swatches
                        HStack(spacing: 12) {
                            ForEach(0..<themes.count, id: \.self) { idx in
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: themes[idx].colors,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedThemeIndex == idx ? PastelTheme.pastelOat : Color.clear, lineWidth: 2.5)
                                    )
                                    .scaleEffect(selectedThemeIndex == idx ? 1.15 : 1.0)
                                    .onTapGesture {
                                        HapticManager.lightImpact()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedThemeIndex = idx
                                        }
                                    }
                            }
                        }
                        
                        // MARK: - Playlist Metadata Inputs
                        VStack(spacing: 12) {
                            TextField("Playlist Name", text: $title)
                                .font(.system(size: 17, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 48)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                )
                            
                            TextField("Description (optional)", text: $descriptionText)
                                .font(.system(size: 14))
                                .foregroundColor(PastelTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .frame(height: 44)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 16)
                        
                        // MARK: - Add Tracks Section
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("SELECT TRACKS")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundColor(PastelTheme.textSecondary)
                                Spacer()
                                Text("\(selectedTrackIds.count) selected")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                            }
                            .padding(.horizontal, 16)
                            
                            // Mini search bar for track picker
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 13))
                                    .foregroundColor(PastelTheme.textTertiary)
                                TextField("Filter library tracks...", text: $searchTrackText)
                                    .font(.system(size: 14))
                                    .foregroundColor(PastelTheme.textPrimary)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 38)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .padding(.horizontal, 16)
                            
                            // Track picker list
                            VStack(spacing: 4) {
                                ForEach(availableTracks) { track in
                                    let isSelected = selectedTrackIds.contains(track.id)
                                    
                                    Button {
                                        HapticManager.lightImpact()
                                        if isSelected {
                                            selectedTrackIds.remove(track.id)
                                        } else {
                                            selectedTrackIds.insert(track.id)
                                        }
                                    } label: {
                                        HStack(spacing: 12) {
                                            // Checkbox Circle
                                            ZStack {
                                                Circle()
                                                    .stroke(isSelected ? PastelTheme.emeraldSuccess : PastelTheme.cardBorder, lineWidth: 1.5)
                                                    .frame(width: 22, height: 22)
                                                
                                                if isSelected {
                                                    Circle()
                                                        .fill(PastelTheme.emeraldSuccess)
                                                        .frame(width: 14, height: 14)
                                                }
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(track.title)
                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                    .foregroundColor(PastelTheme.textPrimary)
                                                    .lineLimit(1)
                                                
                                                Text(track.primaryArtist)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(PastelTheme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            PlatformBrandBadgeView(
                                                type: track.spotifyId != nil ? .spotify : (track.appleMusicId != nil ? .appleMusic : .yandexMusic),
                                                size: 18
                                            )
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? PastelTheme.cardBorderFocused.opacity(0.12) : PastelTheme.card)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // MARK: - Create Action Button
                        Button {
                            createPlaylist()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Create Playlist")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(title.trimmingCharacters(in: .whitespaces).isEmpty ? PastelTheme.cardSubtle : PastelTheme.pastelOat)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("New Playlist")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(PastelTheme.textSecondary)
                }
            }
        }
    }
    
    private func createPlaylist() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        
        let chosenTracks = availableTracks.filter { selectedTrackIds.contains($0.id) }
        _ = coordinator.createPlaylist(
            title: cleanTitle,
            description: descriptionText.isEmpty ? nil : descriptionText,
            tracks: chosenTracks
        )
        HapticManager.successNotification()
        dismiss()
    }
}

