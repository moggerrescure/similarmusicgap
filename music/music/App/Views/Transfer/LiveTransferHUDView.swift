import SwiftUI

/// Live Transfer HUD with Real-Time Precision Progress (P0 - T2, T3, T5)
public struct LiveTransferHUDView: View {
    @ObservedObject var transferManager = TransferManager.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                Spacer()
                
                // MARK: - Central Circular Progress Ring
                ZStack {
                    // Track circle
                    Circle()
                        .stroke(PastelTheme.cardBorder, lineWidth: 14)
                        .frame(width: 230, height: 230)
                    
                    // Animated Progress Bar
                    Circle()
                        .trim(from: 0.0, to: CGFloat(transferManager.progress))
                        .stroke(
                            AngularGradient(
                                colors: [PastelTheme.emeraldSuccess, PastelTheme.pastelOat],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 230, height: 230)
                        .animation(.linear(duration: 0.2), value: transferManager.progress)
                    
                    // Inside HUD Stats
                    VStack(spacing: 4) {
                        Text("\(Int(transferManager.progress * 100))%")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        
                        Text("\(transferManager.processedCount) of \(transferManager.totalToProcess)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                }
                
                // MARK: - Current Track Ticker
                VStack(spacing: 8) {
                    Text("NOW TRANSFERRING")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    
                    Text(transferManager.currentTrackTitle.isEmpty ? "Connecting to Target Stream..." : transferManager.currentTrackTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .padding(.horizontal, 24)
                    
                    Text(transferManager.currentTrackArtist)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(PastelTheme.textSecondary)
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
                
                // Status hint
                Text("Preserving original playlist track order & metadata.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(PastelTheme.textTertiary)
                    .padding(.bottom, 20)
            }
        }
        .interactiveDismissDisabled(transferManager.isMigrating)
    }
}

