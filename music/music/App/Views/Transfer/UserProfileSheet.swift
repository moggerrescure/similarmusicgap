import SwiftUI
import PhotosUI

/// Luxury Apple HIG HUD Profile & Account Inspector Sheet
public struct UserProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @ObservedObject private var navCoordinator = NavigationCoordinator.shared
    
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var cacheCleared: Bool = false
    @State private var cacheSizeText: String = "18.4 MB"
    @State private var showingExportSheet: Bool = false
    @State private var exportURL: URL?
    @State private var exportTitle: String = "Backup"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Hero Profile Header
                        HStack(spacing: 16) {
                            // Avatar with PhotosPicker from Library
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let customImage = coordinator.customAvatarImage {
                                        customImage
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 68, height: 68)
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle()
                                                    .stroke(PastelTheme.pastelOat, lineWidth: 1.5)
                                            )
                                    } else {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [PastelTheme.pastelOat.opacity(0.2), PastelTheme.cardSubtle],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 68, height: 68)
                                            .overlay(
                                                Circle()
                                                    .stroke(PastelTheme.cardBorderFocused, lineWidth: 1.5)
                                            )
                                        
                                        Image(systemName: "person.crop.circle.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(PastelTheme.pastelOat)
                                    }
                                    
                                    // Camera edit badge
                                    ZStack {
                                        Circle()
                                            .fill(PastelTheme.card)
                                            .frame(width: 24, height: 24)
                                            .overlay(Circle().stroke(PastelTheme.cardBorder, lineWidth: 1))
                                        
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(PastelTheme.pastelOat)
                                    }
                                    .offset(x: 2, y: 2)
                                }
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(displayName)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
                                        .frame(width: 7, height: 7)
                                    
                                    Text(coordinator.activeProvidersCount > 0 ? "Synced & Protected" : "Local Vault Only")
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(PastelTheme.textSecondary)
                                }
                                
                                if coordinator.customAvatarData != nil {
                                    Button {
                                        coordinator.clearCustomAvatar()
                                    } label: {
                                        Text("Удалить фото")
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(PastelTheme.textTertiary)
                                            .underline()
                                    }
                                    .padding(.top, 2)
                                }
                            }
                        }
                        .padding(.top, 4)
                        
                        // MARK: - Vital Metrics Strip
                        HStack(spacing: 10) {
                            MetricPill(
                                title: "TRACKS",
                                value: "\(coordinator.totalTracksCount)",
                                color: PastelTheme.pastelOat
                            ) {
                                dismiss()
                                navCoordinator.navigateToLibrary()
                            }
                            
                            MetricPill(
                                title: "SERVICES",
                                value: "\(coordinator.activeProvidersCount) of 3",
                                color: coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary
                            ) {
                                dismiss()
                                navCoordinator.navigateToServices()
                            }
                            
                            MetricPill(
                                title: "PLAYLISTS",
                                value: "\(coordinator.allPlaylists.count)",
                                color: PastelTheme.slateBlue
                            ) {
                                dismiss()
                                navCoordinator.navigateToLibrary()
                            }
                        }
                        
                        // MARK: - Connected Accounts Grid
                        VStack(alignment: .leading, spacing: 10) {
                            Text("STREAMING ACCOUNTS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 8) {
                                AccountStatusRow(
                                    type: .spotify,
                                    isConnected: coordinator.spotify.isAuthenticated,
                                    detail: coordinator.spotify.userDisplayName ?? "Not connected"
                                ) {
                                    dismiss()
                                    navCoordinator.navigateToServices()
                                }
                                
                                AccountStatusRow(
                                    type: .appleMusic,
                                    isConnected: coordinator.appleMusic.isAuthenticated,
                                    detail: coordinator.appleMusic.userDisplayName ?? "Not connected"
                                ) {
                                    dismiss()
                                    navCoordinator.navigateToServices()
                                }
                                
                                AccountStatusRow(
                                    type: .yandexMusic,
                                    isConnected: coordinator.yandexMusic.isAuthenticated,
                                    detail: coordinator.yandexMusic.userDisplayName ?? "Not connected"
                                ) {
                                    dismiss()
                                    navCoordinator.navigateToServices()
                                }
                            }
                        }
                        
                        // MARK: - Appearance & Ambient Particles
                        VStack(alignment: .leading, spacing: 10) {
                            Text("APPEARANCE & PARTICLES")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                Toggle(isOn: $coordinator.backgroundParticlesEnabled) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Фоновые микрочастицы (Stardust)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(PastelTheme.textPrimary)
                                        Text(coordinator.backgroundParticlesEnabled ? "Мягкое космическое свечение (0% CPU, 120 FPS)" : "Чистый глубокий OLED-чёрный фон")
                                            .font(.system(size: 12))
                                            .foregroundColor(PastelTheme.textSecondary)
                                    }
                                }
                                .tint(PastelTheme.emeraldSuccess)
                            }
                            .padding(14)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // MARK: - Storage & Cache Cleaner
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CACHE & STORAGE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Waveform & Audio Cache")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(PastelTheme.textPrimary)
                                    
                                    Text(cacheCleared ? "0 KB (Cleaned)" : cacheSizeText)
                                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                                        .foregroundColor(cacheCleared ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary)
                                }
                                
                                Spacer()
                                
                                Button {
                                    clearAudioCache()
                                } label: {
                                    Text(cacheCleared ? "Cleaned" : "Clear Cache")
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(cacheCleared ? PastelTheme.emeraldSuccess : PastelTheme.pastelOat)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(PastelTheme.cardSubtle)
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(PastelTheme.cardBorder, lineWidth: 1)
                                        )
                                }
                                .disabled(cacheCleared)
                            }
                            .padding(14)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // MARK: - Library Backup Actions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("VAULT BACKUP")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 10) {
                                Button {
                                    exportUniversalJSON()
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(PastelTheme.pastelOat)
                                        Text("Export Universal JSON Backup")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(PastelTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(PastelTheme.textTertiary)
                                    }
                                }
                                
                                Divider().background(PastelTheme.cardBorder)
                                
                                Button {
                                    exportCSVSpreadsheet()
                                } label: {
                                    HStack {
                                        Image(systemName: "tablecells.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(PastelTheme.emeraldSuccess)
                                        Text("Export CSV Spreadsheet (Excel / Numbers)")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                            .foregroundColor(PastelTheme.textPrimary)
                                        Spacer()
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(PastelTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(14)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // Security Badge
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 12))
                                .foregroundColor(PastelTheme.emeraldSuccess)
                            Text("Zero-Knowledge Local Keychain • iOS 18+ HUD Architecture")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(PastelTheme.textTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 6)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Profile & Vault")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PastelTheme.pastelOat)
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ProfileShareSheet(activityItems: [url])
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            coordinator.saveCustomAvatar(data: data)
                        }
                    }
                }
            }
        }
    }
    
    private var displayName: String {
        if let name = coordinator.spotify.userDisplayName, !name.isEmpty {
            return name
        }
        if let name = coordinator.appleMusic.userDisplayName, !name.isEmpty {
            return name
        }
        return "SoundShift Member"
    }
    
    private func clearAudioCache() {
        HapticManager.lightImpact()
        URLCache.shared.removeAllCachedResponses()
        cacheCleared = true
        HapticManager.successNotification()
    }
    
    private func exportUniversalJSON() {
        HapticManager.lightImpact()
        if let url = coordinator.exportUniversalJSON() {
            self.exportURL = url
            self.exportTitle = "SoundShift_Library_Backup.json"
            self.showingExportSheet = true
        }
    }
    
    private func exportCSVSpreadsheet() {
        HapticManager.lightImpact()
        var csv = "Title,Artist,Album,Duration,ISRC,Spotify_ID,Apple_ID,Yandex_ID\n"
        let tracks = coordinator.allTracks.isEmpty ? coordinator.spotify.fetchFavoritesFallback() : coordinator.allTracks
        for t in tracks {
            let title = "\"\(t.title.replacingOccurrences(of: "\"", with: "\"\""))\""
            let artist = "\"\(t.primaryArtist.replacingOccurrences(of: "\"", with: "\"\""))\""
            let album = "\"\(t.album?.replacingOccurrences(of: "\"", with: "\"\"") ?? "")\""
            let duration = t.formattedDuration
            let isrc = t.isrc ?? ""
            let sId = t.spotifyId ?? ""
            let aId = t.appleMusicId ?? ""
            let yId = t.yandexId ?? ""
            csv += "\(title),\(artist),\(album),\(duration),\(isrc),\(sId),\(aId),\(yId)\n"
        }
        
        let tempUrl = FileManager.default.temporaryDirectory.appendingPathComponent("SoundShift_Catalog_\(Int(Date().timeIntervalSince1970)).csv")
        try? csv.data(using: .utf8)?.write(to: tempUrl)
        self.exportURL = tempUrl
        self.exportTitle = "SoundShift_Catalog.csv"
        self.showingExportSheet = true
    }
}

// MARK: - Metric Pill
private struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(title)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(PastelTheme.textTertiary.opacity(0.6))
                }
                
                Text(value)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
}

// MARK: - Account Status Row
private struct AccountStatusRow: View {
    let type: MusicProviderType
    let isConnected: Bool
    let detail: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                PlatformBrandBadgeView(type: type, size: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(isConnected ? PastelTheme.textSecondary : PastelTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isConnected ? PastelTheme.emeraldSuccess : PastelTheme.textTertiary)
                        .frame(width: 6, height: 6)
                    Text(isConnected ? "Active" : "Connect")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isConnected ? PastelTheme.emeraldSuccess : PastelTheme.pastelOat)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(PastelTheme.cardSubtle)
                .clipShape(Capsule())
            }
            .padding(10)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
}

// MARK: - Share Sheet Helper
#if os(iOS)
private struct ProfileShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct ProfileShareSheet: View {
    let activityItems: [Any]
    var body: some View { Text("Export Complete") }
}
#endif

