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
                                color: PastelTheme.pastelOat
                            )
                            HUDMetricBox(
                                title: "CONNECTED",
                                value: "\(coordinator.activeProvidersCount) of 3",
                                color: coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.textSecondary
                            )
                            HUDMetricBox(
                                title: "PLAYLISTS",
                                value: "\(coordinator.allPlaylists.count)",
                                color: PastelTheme.slateBlue
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(PastelTheme.textTertiary)
            
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PastelTheme.cardSubtle)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: type.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(hex: type.brandColorHex))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(type.displayName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    if let onConfigure = onConfigure {
                        Button(action: onConfigure) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(PastelTheme.textTertiary)
                        }
                    }
                }
                
                Text(isAuthenticated ? "\(trackCount) tracks • \(userDisplayName ?? "Connected")" : (onConfigure != nil && !SpotifyConfig.isConfigured ? "Setup required" : "Not connected"))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(isAuthenticated ? PastelTheme.textSecondary : PastelTheme.textTertiary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Action button
            if isAuthenticated {
                Button(action: onRevoke) {
                    Text("Disconnect")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PastelTheme.textTertiary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                }
            } else {
                Button(action: onConnect) {
                    Text("Connect")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textOnOat)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(PastelTheme.pastelOat)
                        .clipShape(Capsule())
                }
                .buttonStyle(TouchFeedbackButtonStyle())
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
