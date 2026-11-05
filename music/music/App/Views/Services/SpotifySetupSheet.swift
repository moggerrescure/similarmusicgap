import SwiftUI

/// Apple HIG HUD Sheet for configuring Spotify Client ID and launching live PKCE auth
public struct SpotifySetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var coordinator = ServicesCoordinator.shared
    
    @State private var clientIdInput: String = SpotifyConfig.activeClientId
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        
                        // MARK: - Service Badge Header
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(PastelTheme.emeraldSuccess.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(PastelTheme.emeraldSuccess)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spotify Live API")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                
                                Text("OAuth 2.0 PKCE on-device integration")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(PastelTheme.textSecondary)
                            }
                        }
                        
                        // MARK: - Setup Steps Card
                        VStack(alignment: .leading, spacing: 14) {
                            Text("SETUP INSTRUCTIONS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            StepRow(number: "1", title: "Open Spotify Dashboard", detail: "Go to developer.spotify.com/dashboard and log in.")
                            StepRow(number: "2", title: "Create Application", detail: "Click Create App, name it SoundShift, choose Web API.")
                            StepRow(number: "3", title: "Set Redirect URI", detail: "Add exact URI: soundshift://spotify-callback")
                            StepRow(number: "4", title: "Copy Client ID", detail: "Paste the 32-character string below.")
                        }
                        .padding(16)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                        
                        // MARK: - Client ID Input Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("SPOTIFY CLIENT ID")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            HStack {
                                TextField("Enter 32-character Client ID", text: $clientIdInput)
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundColor(PastelTheme.textPrimary)
                                    .autocorrectionDisabled()
                                    #if os(iOS)
                                    .textInputAutocapitalization(.never)
                                    #endif
                                
                                if !clientIdInput.isEmpty {
                                    Button {
                                        clientIdInput = ""
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 14))
                                            .foregroundColor(PastelTheme.textTertiary)
                                    }
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(clientIdInput.isEmpty ? PastelTheme.cardBorder : PastelTheme.cardBorderFocused, lineWidth: 1)
                            )
                        }
                        
                        // Error message banner if any
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.red)
                                Text(error)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        
                        // MARK: - Actions
                        VStack(spacing: 12) {
                            // Primary Connect Button
                            Button {
                                initiateConnect()
                            } label: {
                                HStack(spacing: 8) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(PastelTheme.textOnOat)
                                    } else {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 14, weight: .bold))
                                        Text("Authorize Live Account")
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                    }
                                }
                                .foregroundColor(PastelTheme.textOnOat)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(PastelTheme.pastelOat)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .disabled(isLoading || clientIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(clientIdInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.4 : 1.0)
                            
                            // Secondary Demo Mode Button
                            Button {
                                initiateDemoMode()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.square")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Continue in Demo Mode (Mock Data)")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(PastelTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                                )
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Connect Spotify")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PastelTheme.textSecondary)
                }
            }
        }
    }
    
    private func initiateConnect() {
        let cleanId = clientIdInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanId.isEmpty else { return }
        
        SpotifyConfig.activeClientId = cleanId
        isLoading = true
        errorMessage = nil
        HapticManager.lightImpact()
        
        Task {
            do {
                _ = try await coordinator.spotify.authenticate(isDemoMode: false)
                await coordinator.syncAll()
                await MainActor.run {
                    isLoading = false
                    HapticManager.successNotification()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    HapticManager.errorNotification()
                }
            }
        }
    }
    
    private func initiateDemoMode() {
        isLoading = true
        HapticManager.lightImpact()
        Task {
            _ = try? await coordinator.spotify.authenticate(isDemoMode: true)
            await coordinator.syncAll()
            await MainActor.run {
                isLoading = false
                HapticManager.successNotification()
                dismiss()
            }
        }
    }
}

// MARK: - Step Row Helper
private struct StepRow: View {
    let number: String
    let title: String
    let detail: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(PastelTheme.cardSubtle)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle().stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                
                Text(number)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.pastelOat)
            }
            .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(PastelTheme.textSecondary)
                    .lineSpacing(2)
            }
        }
    }
}

