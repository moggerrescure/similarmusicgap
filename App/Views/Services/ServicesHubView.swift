import SwiftUI

/// Screen 2: Connected Services Hub & Zero-Knowledge Privacy Center (P0 - A4, A5)
public struct ServicesHubView: View {
    @StateObject private var coordinator = ServicesCoordinator.shared
    @State private var showingExportSheet: Bool = false
    @State private var exportURL: URL?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // MARK: - Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Connected Services")
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            
                            Text("Manage streaming providers, sync status, and tokens.")
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        .padding(.top, 8)
                        
                        // MARK: - Global HUD Metric Strip
                        HStack(spacing: 12) {
                            HUDMetricBox(
                                title: "TOTAL TRACKS",
                                value: "\(coordinator.totalTracksCount)",
                                color: PastelTheme.pastelOat
                            )
                            HUDMetricBox(
                                title: "ACTIVE HUBS",
                                value: "\(coordinator.activeProvidersCount)/3",
                                color: coordinator.activeProvidersCount > 0 ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning
                            )
                            HUDMetricBox(
                                title: "PLAYLISTS",
                                value: "\(coordinator.allPlaylists.count)",
                                color: PastelTheme.slateBlue
                            )
                        }
                        
                        // MARK: - Service Cards List (A4)
                        VStack(spacing: 16) {
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
                                    Task { await coordinator.authenticate(type: .spotify) }
                                },
                                onRevoke: {
                                    Task { await coordinator.revoke(type: .spotify) }
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
                        
                        // MARK: - Zero-Knowledge Privacy Center (A5, C8)
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                                
                                Text("PRIVACY CENTER & ZERO-KNOWLEDGE")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .tracking(1.0)
                                    .foregroundColor(PastelTheme.pastelOat)
                            }
                            
                            Text("All streaming tokens are stored exclusively in the iOS Secure Enclave Keychain with zero-cloud exposure. You can revoke connections or export full raw data at any moment.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineSpacing(3)
                            
                            Divider()
                                .background(PastelTheme.cardBorder)
                            
                            HStack {
                                Button {
                                    HapticManager.lightImpact()
                                    if let url = coordinator.exportUniversalJSON() {
                                        self.exportURL = url
                                        self.showingExportSheet = true
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "square.and.arrow.up")
                                            .font(.system(size: 14, weight: .medium))
                                        Text("Export Universal JSON (Backup)")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(PastelTheme.pastelOat)
                                }
                                
                                Spacer()
                                
                                Text("C8: Complete Data")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(PastelTheme.textTertiary)
                            }
                        }
                        .padding(18)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                        
                        // MARK: - Taste DNA Banner Card (S1-S3, SO1)
                        NavigationLink {
                            TasteAnalyticsView()
                        } label: {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(PastelTheme.lavenderAI.opacity(0.15))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(PastelTheme.lavenderAI)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(PastelTheme.lavenderAI.opacity(0.35), lineWidth: 1)
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("AI Taste Intelligence & DNA")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                            .foregroundColor(PastelTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text("9:16 Story")
                                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                                            .foregroundColor(PastelTheme.pastelOat)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(PastelTheme.cardSubtle)
                                            .clipShape(Capsule())
                                    }
                                    
                                    Text("Acoustic radar, decade affinity & viral 9:16 passport")
                                        .font(.system(size: 12))
                                        .foregroundColor(PastelTheme.textSecondary)
                                }
                            }
                            .padding(16)
                            .background(PastelTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(PastelTheme.lavenderAI.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .buttonStyle(TouchFeedbackButtonStyle())
                        
                        // MARK: - Bottom Primary Action: Start Transfer
                        if coordinator.activeProvidersCount >= 2 {
                            NavigationLink {
                                TransferConfigView()
                            } label: {
                                HStack(spacing: 8) {
                                    Text("Proceed to Migration Hub")
                                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(PastelTheme.textOnOat)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(PastelTheme.pastelOat)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.lightImpact()
                        Task { await coordinator.syncAll() }
                    } label: {
                        if coordinator.isSyncing {
                            ProgressView()
                                .tint(PastelTheme.pastelOat)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 15, weight: .semibold))
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
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(PastelTheme.textTertiary)
            
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Individual Service Card (A4)
private struct ServiceCardView: View {
    let type: MusicProviderType
    let isAuthenticated: Bool
    let userDisplayName: String?
    let trackCount: Int
    let onConnect: () -> Void
    let onRevoke: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                // Service Color Accent Dot
                Circle()
                    .fill(Color(hex: type.brandColorHex))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(type.displayName)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    
                    Text(isAuthenticated ? (userDisplayName ?? "Connected") : "Not Linked")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(isAuthenticated ? PastelTheme.textSecondary : PastelTheme.textTertiary)
                }
                
                Spacer()
                
                // Live Status Pill
                HStack(spacing: 5) {
                    Circle()
                        .fill(isAuthenticated ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
                        .frame(width: 6, height: 6)
                    
                    Text(isAuthenticated ? "\(trackCount) tracks" : "Standby")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(isAuthenticated ? PastelTheme.emeraldSuccess : PastelTheme.amberWarning)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(PastelTheme.cardSubtle)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isAuthenticated ? PastelTheme.emeraldSuccess.opacity(0.3) : PastelTheme.cardBorder, lineWidth: 0.5)
                )
            }
            
            Divider()
                .background(PastelTheme.cardBorder)
            
            // Action Buttons in 1 Tap
            HStack {
                if isAuthenticated {
                    Button {
                        HapticManager.lightImpact()
                        onConnect()
                    } label: {
                        Text("Re-auth")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(role: .destructive) {
                        HapticManager.mediumImpact()
                        onRevoke()
                    } label: {
                        Text("Disconnect (Revoke)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.red.opacity(0.85))
                    }
                } else {
                    Button {
                        HapticManager.lightImpact()
                        onConnect()
                    } label: {
                        HStack(spacing: 6) {
                            Text("Connect \(type.displayName)")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Image(systemName: "link")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(PastelTheme.pastelOat)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                }
            }
        }
        .padding(18)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isAuthenticated ? PastelTheme.cardBorderFocused : PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Native iOS Share Sheet Helper
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
    var body: some View {
        Text("Share Sheet: \(activityItems.description)")
    }
}
#endif

#Preview {
    ServicesHubView()
}

