import SwiftUI

/// Screen: Connected Services Hub & Security Center
public struct ServicesHubView: View {
    @StateObject private var coordinator = ServicesCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingExportSheet: Bool = false
    @State private var showingSpotifySetup: Bool = false
    @State private var exportURL: URL?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AmbientWashBackgroundView(tab: .home)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Global HUD Metric Strip
                        HStack(spacing: 10) {
                            HUDMetricBox(
                                title: "TRACKS",
                                value: "\(coordinator.totalTracksCount)",
                                color: PastelTheme.pastelOat,
                                onTap: {
                                    dismiss()
                                    NavigationCoordinator.shared.navigateToLibrary()
                                }
                            )
                            HUDMetricBox(
                                title: "CONNECTED",
                                value: "\(coordinator.activeProvidersCount) of \(MusicProviderType.availableConnectors.count)",
                                color: coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary,
                                onTap: nil
                            )
                            HUDMetricBox(
                                title: "PLAYLISTS",
                                value: "\(coordinator.allPlaylists.count)",
                                color: PastelTheme.slateBlue,
                                onTap: {
                                    dismiss()
                                    NavigationCoordinator.shared.navigateToLibrary()
                                }
                            )
                        }
                        
                        if !coordinator.lastSyncSummary.isEmpty {
                            Text(coordinator.lastSyncSummary)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        
                        if let error = coordinator.lastErrorMessage {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(PastelTheme.amberWarning)
                                Text(error)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(PastelTheme.textSecondary)
                                Spacer(minLength: 0)
                                Button("Dismiss") {
                                    coordinator.lastErrorMessage = nil
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(PastelTheme.pastelOat)
                            }
                            .padding(12)
                            .background(PastelTheme.amberWarning.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        // MARK: - Streaming Providers List
                        VStack(alignment: .leading, spacing: 10) {
                            Text("STREAMING ACCOUNTS")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            Text("LIVE = real account (migrate OK). DEMO / SIM = practice only — Sync & migrate stay blocked.")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(PastelTheme.textTertiary)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                ServiceCardView(
                                    type: .spotify,
                                    isAuthenticated: coordinator.spotify.isAuthenticated,
                                    isLiveSession: coordinator.spotify.isLiveSession,
                                    userDisplayName: coordinator.spotify.userDisplayName,
                                    trackCount: max(coordinator.spotify.trackCount, coordinator.tracks(for: .spotify).count),
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
                                    },
                                    statusHint: {
                                        if coordinator.spotify.isUsingDemoData { return "Demo data" }
                                        if coordinator.spotify.isAuthenticated && !SpotifyConfig.isConfigured {
                                            return "Client ID required"
                                        }
                                        if coordinator.spotify.isAuthenticated && !coordinator.spotify.isLiveSession {
                                            return "Not a live session"
                                        }
                                        return nil
                                    }()
                                )
                                
                                ServiceCardView(
                                    type: .appleMusic,
                                    isAuthenticated: coordinator.appleMusic.isAuthenticated,
                                    isLiveSession: coordinator.appleMusic.isLiveSession,
                                    userDisplayName: coordinator.appleMusic.userDisplayName,
                                    trackCount: max(coordinator.appleMusic.trackCount, coordinator.tracks(for: .appleMusic).count),
                                    onConnect: {
                                        Task { await coordinator.authenticate(type: .appleMusic) }
                                    },
                                    onRevoke: {
                                        Task { await coordinator.revoke(type: .appleMusic) }
                                    },
                                    statusHint: {
                                        #if targetEnvironment(simulator)
                                        "Use a physical iPhone — Simulator library is often empty"
                                        #else
                                        if coordinator.appleMusic.isAuthenticated && !coordinator.appleMusic.isLiveSession {
                                            return "Not a live session"
                                        }
                                        if coordinator.appleMusic.isLiveSession {
                                            return "Syncs full Music library (not only Loved)"
                                        }
                                        return nil
                                        #endif
                                    }()
                                )
                                
                                if YandexMusicProvider.isConnectorEnabled {
                                    ServiceCardView(
                                        type: .yandexMusic,
                                        isAuthenticated: coordinator.yandexMusic.isAuthenticated,
                                        isLiveSession: coordinator.yandexMusic.isLiveSession,
                                        userDisplayName: coordinator.yandexMusic.userDisplayName,
                                        trackCount: max(
                                            coordinator.yandexMusic.trackCount,
                                            coordinator.tracks(for: .yandexMusic).count
                                        ),
                                        onConnect: {
                                            NavigationCoordinator.shared.openYandexConnect()
                                        },
                                        onRevoke: {
                                            Task { await coordinator.revoke(type: .yandexMusic) }
                                        }
                                    )
                                }
                            }
                        }
                        
                        // MARK: - Migration CTA
                        Button {
                            HapticManager.lightImpact()
                            dismiss()
                            NavigationCoordinator.shared.navigateToMove()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.left.arrow.right.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Move library between services")
                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                    Text("Spotify · Apple Music · Yandex — LIVE accounts only")
                                        .font(.system(size: 12, weight: .medium))
                                        .opacity(0.85)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(PastelTheme.textOnOat)
                            .padding(16)
                            .background(PastelTheme.pastelOat)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(TouchFeedbackButtonStyle())
                        
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
                                    } else {
                                        coordinator.lastErrorMessage = "Nothing to export yet — sync a library first."
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
            .navigationTitle("Connect")
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
            .task {
                await coordinator.syncIfNeededWhileVisible()
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
    let isLiveSession: Bool
    let userDisplayName: String?
    let trackCount: Int
    let onConnect: () -> Void
    let onRevoke: () -> Void
    var onConfigure: (() -> Void)? = nil
    var isAvailable: Bool = true
    var unavailableReason: String? = nil
    var statusHint: String? = nil
    
    private var bannerName: String {
        switch type {
        case .spotify: return "spotify_banner"
        case .appleMusic: return "apple_music_banner"
        case .yandexMusic: return "yandex_music_banner"
        }
    }
    
    private var subtitle: String {
        if !isAvailable {
            return unavailableReason ?? "Coming soon"
        }
        if isAuthenticated {
            let base = "\(trackCount) tracks • \(userDisplayName ?? "Connected")"
            if let statusHint { return "\(base) • \(statusHint)" }
            if !isLiveSession { return "\(base) • Not live" }
            return base
        }
        if onConfigure != nil && !SpotifyConfig.isConfigured {
            return "Setup required • Tap to configure"
        }
        return "Tap Connect to sync library"
    }
    
    /// DEMO / SIM / LIVE — LIVE only when `isLiveSession` is true (never trust auth alone).
    private var connectionBadge: (title: String, color: Color) {
        if isLiveSession {
            return ("LIVE", PastelTheme.emeraldSuccess)
        }
        if statusHint == "Demo data" {
            return ("DEMO", PastelTheme.amberWarning)
        }
        if statusHint == "Client ID required" {
            return ("SETUP", PastelTheme.amberWarning)
        }
        return ("SIM", PastelTheme.amberWarning)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                Image(bannerName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(isAvailable ? 0.38 : 0.18)
            }
            
            LinearGradient(
                stops: [
                    .init(color: PastelTheme.card.opacity(0.92), location: 0.0),
                    .init(color: PastelTheme.card.opacity(0.72), location: 0.50),
                    .init(color: PastelTheme.card.opacity(0.86), location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            
            RadialGradient(
                colors: [Color(hex: type.brandColorHex).opacity(isAvailable ? 0.18 : 0.08), Color.clear],
                center: .trailing,
                startRadius: 20,
                endRadius: 260
            )
            
            HStack(spacing: 14) {
                PlatformBrandBadgeView(type: type, size: 46)
                    .opacity(isAvailable ? 1 : 0.55)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(type.displayName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        
                        if isAuthenticated {
                            let badge = connectionBadge
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(badge.color)
                                    .frame(width: 5, height: 5)
                                Text(badge.title)
                                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                                    .foregroundColor(badge.color)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.16))
                            .clipShape(Capsule())
                            .accessibilityIdentifier("services.badge.\(badge.title.lowercased())")
                            .accessibilityLabel("\(badge.title) connection")
                            .accessibilityHint(
                                badge.title == "LIVE"
                                ? "Real account. Sync and migrate are allowed."
                                : "Not a live session. Sync and migrate stay blocked until you connect for real."
                            )
                        } else if !isAvailable {
                            Text("SOON")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundColor(PastelTheme.amberWarning)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(PastelTheme.amberWarning.opacity(0.16))
                                .clipShape(Capsule())
                        }
                        
                        if let onConfigure = onConfigure, isAvailable {
                            Button(action: onConfigure) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(isAuthenticated ? PastelTheme.textSecondary : PastelTheme.textTertiary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if !isAvailable {
                    Text("Soon")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(PastelTheme.cardSubtle.opacity(0.85))
                        .clipShape(Capsule())
                } else if isAuthenticated {
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
        .opacity(isAvailable ? 1 : 0.9)
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
