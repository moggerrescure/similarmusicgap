import SwiftUI

/// Screen: Connected Services Hub & Security Center
public struct ServicesHubView: View {
    @StateObject private var coordinator = ServicesCoordinator.shared
    @State private var showingExportSheet: Bool = false
    @State private var showingSpotifySetup: Bool = false
    @State private var exportURL: URL?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Global HUD Metric Strip
                        HStack(spacing: 10) {
                            HUDMetricBox(
                                title: "TRACKS",
                                value: "\(coordinator.totalTracksCount)",
                                color: PastelTheme.pastelOat,
                                onTap: {
                                    NavigationCoordinator.shared.navigateToLibrary()
                                }
                            )
                            HUDMetricBox(
                                title: "CONNECTED",
                                value: "\(coordinator.activeProvidersCount) of 3",
                                color: coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary,
                                onTap: {
                                    NavigationCoordinator.shared.navigateToServices()
                                }
                            )
                            HUDMetricBox(
                                title: "PLAYLISTS",
                                value: "\(coordinator.allPlaylists.count)",
                                color: PastelTheme.slateBlue,
                                onTap: {
                                    NavigationCoordinator.shared.navigateToLibrary()
                                }
                            )
                        }
                        
                        // MARK: - Streaming Providers List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("STREAMING ACCOUNTS")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                ServiceCardView(
                                    type: .yandexMusic,
                                    isAuthenticated: coordinator.yandexMusic.isAuthenticated,
                                    userDisplayName: coordinator.yandexMusic.userDisplayName,
                                    trackCount: coordinator.yandexMusic.trackCount,
                                    onConnect: {
                                        Task { await coordinator.authenticate(type: .yandexMusic) }
                                    },
                                    onRevoke: {
                                        Task { await coordinator.revoke(type: .yandexMusic) }
                                    }
                                )
                                
                                ServiceCardView(
                                    type: .spotify,
                                    isAuthenticated: coordinator.spotify.isAuthenticated,
                                    userDisplayName: coordinator.spotify.userDisplayName,
                                    trackCount: coordinator.spotify.trackCount,
                                    onConnect: {
                                        if SpotifyConfig.isConfigured {
                                            Task { await coordinator.authenticate(type: .spotify) }
                                        } else {
                                            showingSpotifySetup = true
                                        }
                                    },
                                    onRevoke: {
                                        Task { await coordinator.revoke(type: .spotify) }
                                    },
                                    onConfigure: {
                                        showingSpotifySetup = true
                                    }
                                )
                                
                                ServiceCardView(
                                    type: .appleMusic,
                                    isAuthenticated: coordinator.appleMusic.isAuthenticated,
                                    userDisplayName: coordinator.appleMusic.userDisplayName,
                                    trackCount: coordinator.appleMusic.trackCount,
                                    onConnect: {
                                        Task { await coordinator.authenticate(type: .appleMusic) }
                                    },
                                    onRevoke: {
                                        Task { await coordinator.revoke(type: .appleMusic) }
                                    }
                                )
                            }
                        }
                        
                        // MARK: - Privacy & Local Storage
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SECURITY & DATA")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 10) {
                                    Image(systemName: "lock.shield.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(PastelTheme.emeraldSuccess)
                                    
                                    Text("On-Device Keychain Storage")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(PastelTheme.textPrimary)
                                }
                                
                                Text("All authentication tokens remain in the iOS Secure Enclave on this device. No external servers or telemetry.")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(PastelTheme.textSecondary)
                                    .lineSpacing(3)
                                
                                Divider()
                                    .background(PastelTheme.cardBorder)
                                
                                Button {
                                    HapticManager.lightImpact()
                                    if let url = coordinator.exportUniversalJSON() {
                                        self.exportURL = url
                                        self.showingExportSheet = true
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 13, weight: .medium))
                                        Text("Export Library Backup (JSON)")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(PastelTheme.textTertiary)
                                    }
                                    .foregroundColor(PastelTheme.pastelOat)
                                }
                            }
                            .padding(16)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Services")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        HapticManager.lightImpact()
                        Task { await coordinator.syncAll() }
                    } label: {
                        if coordinator.isSyncing {
                            ProgressView()
                                .tint(PastelTheme.pastelOat)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                if let exportURL = exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
            .sheet(isPresented: $showingSpotifySetup) {
                SpotifySetupSheet()
            }
        }
    }
}

// MARK: - HUD Metric Box Component
private struct HUDMetricBox: View {
    let title: String
    let value: String
    let color: Color
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button {
            onTap?()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    Spacer()
                    
                    if onTap != nil {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(PastelTheme.textTertiary.opacity(0.6))
                    }
                }
                
                Text(value)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .background(PastelTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
        .disabled(onTap == nil)
    }
}

// MARK: - Individual Service Card
private struct ServiceCardView: View {
    let type: MusicProviderType
    let isAuthenticated: Bool
    let userDisplayName: String?
    let trackCount: Int
    let onConnect: () -> Void
    let onRevoke: () -> Void
    var onConfigure: (() -> Void)? = nil
    
    private var bannerName: String {
        switch type {
        case .spotify: return "spotify_banner"
        case .appleMusic: return "apple_music_banner"
        case .yandexMusic: return "yandex_music_banner"
        }
    }
    
    var body: some View {
        ZStack {
            // Layer 1: Atmospheric Background Banner Image
            GeometryReader { geo in
                Image(bannerName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.38)
            }
            
            // Layer 2: Deep Dark Glass Scrim for 100% High-Contrast Text
            LinearGradient(
                stops: [
                    .init(color: PastelTheme.card.opacity(0.92), location: 0.0),
                    .init(color: PastelTheme.card.opacity(0.72), location: 0.50),
                    .init(color: PastelTheme.card.opacity(0.86), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            // Layer 3: Brand Ambient Radial Glow
            RadialGradient(
                colors: [Color(hex: type.brandColorHex).opacity(0.18), Color.clear],
                center: .trailing,
                startRadius: 20,
                endRadius: 260
            )
            
            // Layer 4: Interactive HUD Content
            HStack(spacing: 14) {
                // Official Vector Brand Badge
                PlatformBrandBadgeView(type: type, size: 46)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(type.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        
                        if isAuthenticated {
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(PastelTheme.emeraldSuccess)
                                    .frame(width: 5, height: 5)
                                Text("LIVE")
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(PastelTheme.emeraldSuccess.opacity(0.16))
                            .clipShape(Capsule())
                        }
                        
                        if let onConfigure = onConfigure {
                            Button(action: onConfigure) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                        }
                    }
                    
                    Text(isAuthenticated ? "\(trackCount) tracks • \(userDisplayName ?? "Connected")" : (onConfigure != nil && !SpotifyConfig.isConfigured ? "Setup required • Tap to configure" : "Tap Connect to sync library"))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(isAuthenticated ? PastelTheme.textSecondary : PastelTheme.textTertiary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Action Button
                if isAuthenticated {
                    Button(action: onRevoke) {
                        Text("Disconnect")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(PastelTheme.cardSubtle.opacity(0.85))
                            .clipShape(Capsule())
                    }
                } else {
                    Button(action: onConnect) {
                        Text("Connect")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textOnOat)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .frame(minHeight: 76)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(hex: type.brandColorHex).opacity(0.45),
                            PastelTheme.cardBorder,
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Share Sheet Helper
#if os(iOS)
private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct ShareSheet: View {
    let activityItems: [Any]
    var body: some View { Text("Export Complete") }
}
#endif

#if DEBUG
struct ServicesHubView_Previews: PreviewProvider {
    static var previews: some View {
        ServicesHubView()
    }
}
#endif
