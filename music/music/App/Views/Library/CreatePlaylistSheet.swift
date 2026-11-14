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
    @State private var destination: MusicProviderType = .spotify
    @State private var isSaving: Bool = false
    @State private var saveError: String?
    
    // Preset cover gradient themes
    private let themes: [(name: String, colors: [Color])] = [
        ("Aurora Emerald", [PastelTheme.emeraldSuccess, Color(hex: "#065F46")]),
        ("Solar Amber", [Color(hex: "#F59E0B"), Color(hex: "#78350F")]),
        ("Rose Liquid", [Color(hex: "#FB7185"), Color(hex: "#831843")]),
        ("Midnight Slate", [Color(hex: "#60A5FA"), Color(hex: "#1E3A8A")]),
        ("Oat Cashmere", [PastelTheme.pastelOat, Color(hex: "#27272A")])
    ]
    
    private var availableDestinations: [MusicProviderType] {
        MusicProviderType.availableConnectors.filter { coordinator.provider(for: $0).isAuthenticated }
    }
    
    private var availableTracks: [UniversalTrack] {
        let list = coordinator.allTracks
        if searchTrackText.isEmpty {
            return list
        }
        let q = searchTrackText.lowercased()
        return list.filter {
            $0.title.lowercased().contains(q) ||
            $0.primaryArtist.lowercased().contains(q)
        }
    }
    
    private var canCreatePlaylist: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !availableDestinations.isEmpty
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
                        
                        if !availableDestinations.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("SAVE TO")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .tracking(0.6)
                                    .foregroundColor(PastelTheme.textTertiary)
                                HStack(spacing: 8) {
                                    ForEach(availableDestinations) { type in
                                        Button {
                                            destination = type
                                            HapticManager.lightImpact()
                                        } label: {
                                            Text(type.displayName)
                                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                                .foregroundColor(destination == type ? PastelTheme.textOnOat : PastelTheme.textSecondary)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(destination == type ? PastelTheme.pastelOat : PastelTheme.cardSubtle)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Connect a service first")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                Text("Playlists save to Spotify or Apple Music — local-only stubs are disabled so nothing looks “saved” when it isn’t.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PastelTheme.amberWarning)
                                Button {
                                    HapticManager.lightImpact()
                                    dismiss()
                                    NavigationCoordinator.shared.navigateToConnect()
                                } label: {
                                    Text("Open Connect")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(PastelTheme.textOnOat)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(PastelTheme.pastelOat)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        if let saveError {
                            Text(saveError)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.9))
                                .padding(.horizontal, 16)
                        }
                        
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
                            
                            if coordinator.allTracks.isEmpty {
                                Text("No synced tracks yet — you can still create an empty playlist on the service, then Sync to fill the picker.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PastelTheme.textTertiary)
                                    .padding(.horizontal, 16)
                            }
                            
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
                                            
                                            if let badgeType = Self.badgeType(for: track) {
                                                PlatformBrandBadgeView(type: badgeType, size: 18)
                                            }
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
                                if isSaving {
                                    ProgressView()
                                        .tint(PastelTheme.textOnOat)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .bold))
                                }
                                Text(
                                    isSaving
                                    ? "Saving…"
                                    : (availableDestinations.isEmpty ? "Connect to create" : "Create Playlist")
                                )
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                (!canCreatePlaylist || isSaving)
                                ? PastelTheme.cardSubtle
                                : PastelTheme.pastelOat
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(!canCreatePlaylist || isSaving)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        .padding(.bottom, 30)
                        .onAppear {
                            if let first = availableDestinations.first {
                                destination = first
                            }
                        }
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
    
    private static func badgeType(for track: UniversalTrack) -> MusicProviderType? {
        if track.spotifyId != nil { return .spotify }
        if track.appleMusicId != nil { return .appleMusic }
        if YandexMusicProvider.isConnectorEnabled, track.yandexId != nil { return .yandexMusic }
        return nil
    }
    
    private func createPlaylist() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }
        
        // Never invent a local-only playlist — that looked like a service save.
        guard !availableDestinations.isEmpty else {
            saveError = "Connect Spotify or Apple Music before creating a playlist."
            HapticManager.errorNotification()
            dismiss()
            NavigationCoordinator.shared.navigateToConnect()
            return
        }
        
        // Always resolve from full library — search filter must not drop prior selections.
        let chosenTracks = coordinator.allTracks.filter { selectedTrackIds.contains($0.id) }
        
        if !availableDestinations.contains(destination) {
            destination = availableDestinations[0]
        }
        
        isSaving = true
        saveError = nil
        Task {
            do {
                let created = try await coordinator.provider(for: destination).createPlaylist(
                    name: cleanTitle,
                    description: descriptionText.isEmpty ? nil : descriptionText,
                    tracks: chosenTracks
                )
                await MainActor.run {
                    coordinator.ingestRemotePlaylist(created)
                    isSaving = false
                    HapticManager.successNotification()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = error.localizedDescription
                    HapticManager.errorNotification()
                }
            }
        }
    }
}

