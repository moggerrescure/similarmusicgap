import SwiftUI

/// Live Transfer HUD with Real-Time Precision Progress (P0 - T2, T3, T5)
public struct LiveTransferHUDView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    private var phase: MigrationPhase {
        // Trust the manager phase — never flash FAILED from a stale dry-run/block error.
        transferManager.migrationPhase
    }
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(PastelTheme.cardBorder, lineWidth: 14)
                        .frame(width: 230, height: 230)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(transferManager.progress))
                        .stroke(
                            AngularGradient(
                                colors: phase == .failed
                                    ? [Color.red.opacity(0.8), PastelTheme.amberWarning]
                                    : [PastelTheme.emeraldSuccess, PastelTheme.pastelOat],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 230, height: 230)
                        .animation(.linear(duration: 0.2), value: transferManager.progress)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(transferManager.progress * 100))%")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        Text("\(transferManager.processedCount) of \(transferManager.totalToProcess) \(phase.counterLabel.lowercased())")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                }
                
                VStack(spacing: 8) {
                    Text(phase.eyebrow)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(phase == .failed ? Color.red.opacity(0.9) : PastelTheme.emeraldSuccess)
                    
                    Text(
                        transferManager.currentTrackTitle.isEmpty
                            ? (transferManager.statusMessage.isEmpty ? phase.userHint : transferManager.statusMessage)
                            : transferManager.currentTrackTitle
                    )
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 24)
                    
                    if !transferManager.currentTrackArtist.isEmpty {
                        Text(transferManager.currentTrackArtist)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                    
                    if let err = transferManager.lastErrorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 4)
                    } else {
                        Text(phase.userHint)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(PastelTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(PastelTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                if !transferManager.isMigrating {
                    Button {
                        if phase == .done || phase == .failed {
                            transferManager.migrationPhase = .idle
                        }
                        dismiss()
                    } label: {
                        Text(phase == .failed ? "Close" : (phase == .done ? "Done" : "Continue"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(PastelTheme.pastelOat)
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                } else {
                    Text(phase.userHint)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(PastelTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 20)
                }
            }
        }
        .interactiveDismissDisabled(transferManager.isMigrating)
    }
}
