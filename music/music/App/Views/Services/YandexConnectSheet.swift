import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Polished Yandex Music Connect — Device Flow with large code + live poll.
public struct YandexConnectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    
    @State private var userCode: String = ""
    @State private var verificationURL: URL?
    @State private var statusText: String = "Preparing secure sign-in…"
    @State private var errorMessage: String?
    @State private var isPolling: Bool = false
    @State private var pollTask: Task<Void, Never>?
    @State private var manualToken: String = ""
    @State private var showManual: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        
                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color.red.opacity(0.9))
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        codeCard
                        
                        actions
                        
                        Text(statusText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        DisclosureGroup("Paste access token", isExpanded: $showManual) {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Access token", text: $manualToken)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .padding(12)
                                    .background(PastelTheme.cardSubtle)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                Button {
                                    Task { await completeWithManualToken() }
                                } label: {
                                    Text("Connect with token")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(PastelTheme.textOnOat)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                        .background(PastelTheme.pastelOat)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.top, 8)
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PastelTheme.textSecondary)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Yandex Music")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        pollTask?.cancel()
                        dismiss()
                    }
                    .foregroundColor(PastelTheme.pastelOat)
                }
            }
            .task {
                await startDeviceFlow()
            }
            .onDisappear {
                pollTask?.cancel()
            }
        }
    }
    
    private var header: some View {
        HStack(spacing: 12) {
            PlatformBrandBadgeView(type: .yandexMusic, size: 48)
            VStack(alignment: .leading, spacing: 2) {
                Text("Connect Yandex Music")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                Text("Sign in once — then Sync and Move work like Spotify & Apple Music.")
                    .font(.system(size: 13))
                    .foregroundColor(PastelTheme.textSecondary)
            }
        }
    }
    
    private var codeCard: some View {
        VStack(spacing: 14) {
            Text("ENTER THIS CODE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(PastelTheme.textTertiary)
            
            Text(userCode.isEmpty ? "········" : userCode.uppercased())
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
                .monospacedDigit()
                .minimumScaleFactor(0.6)
                .lineLimit(1)
                .accessibilityIdentifier("yandex.user_code")
            
            Text("Open Yandex, approve SoundShift, then this screen finishes automatically.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(PastelTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
    
    private var actions: some View {
        VStack(spacing: 10) {
            Button {
                if let verificationURL {
                    #if os(iOS)
                    UIApplication.shared.open(verificationURL)
                    #endif
                }
            } label: {
                HStack {
                    Image(systemName: "safari")
                    Text("Open Yandex sign-in")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(PastelTheme.textOnOat)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(verificationURL == nil ? PastelTheme.cardSubtle : PastelTheme.pastelOat)
                .clipShape(Capsule())
            }
            .disabled(verificationURL == nil)
            .buttonStyle(MarbleCapsuleButtonStyle(strokeWidth: 1.5))
            
            Button {
                Task { await startDeviceFlow() }
            } label: {
                Text("Refresh code")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(PastelTheme.pastelOat)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @MainActor
    private func startDeviceFlow() async {
        pollTask?.cancel()
        errorMessage = nil
        statusText = "Requesting sign-in code…"
        isPolling = false
        do {
            let code = try await YandexAuthManager.shared.requestDeviceCode()
            userCode = code.userCode
            verificationURL = URL(string: code.verificationUrl)
            statusText = "Waiting for approval…"
            isPolling = true
            pollTask = Task {
                await poll(deviceCode: code.deviceCode, interval: max(code.interval, 3), expiresIn: code.expiresIn)
            }
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Couldn’t start sign-in"
        }
    }
    
    private func poll(deviceCode: String, interval: Int, expiresIn: Int) async {
        let deadline = Date().addingTimeInterval(TimeInterval(expiresIn))
        while Date() < deadline {
            if Task.isCancelled { return }
            do {
                if let token = try await YandexAuthManager.shared.pollDeviceToken(deviceCode: deviceCode) {
                    await finish(with: token)
                    return
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    statusText = "Sign-in failed"
                    isPolling = false
                }
                return
            }
            try? await Task.sleep(nanoseconds: UInt64(interval) * 1_000_000_000)
        }
        await MainActor.run {
            statusText = "Code expired — tap Refresh code"
            isPolling = false
            errorMessage = YandexAuthError.timedOut.localizedDescription
        }
    }
    
    @MainActor
    private func finish(with token: YandexAuthManager.TokenPayload) async {
        statusText = "Finishing…"
        do {
            try await coordinator.yandexMusic.completeLogin(with: token)
            HapticManager.successNotification()
            statusText = "Connected"
            dismiss()
            Task { await coordinator.syncAll() }
        } catch {
            errorMessage = error.localizedDescription
            statusText = "Connected token, but profile sync failed"
        }
    }
    
    @MainActor
    private func completeWithManualToken() async {
        let trimmed = manualToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            let payload = YandexAuthManager.TokenPayload(accessToken: trimmed)
            try await coordinator.yandexMusic.completeLogin(with: payload)
            HapticManager.successNotification()
            dismiss()
            Task { await coordinator.syncAll() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
