import SwiftUI

/// Interactive Flow Bridge View where songs visibly flow from the source service to the destination service
public struct TransferBridgeFlowView: View {
    public let source: MusicProviderType
    public let destination: MusicProviderType
    @ObservedObject var transferManager = TransferManager.shared
    @Environment(\.dismiss) private var dismiss
    
    // Animation state for flowing track capsules
    @State private var streamPhase: CGFloat = 0.0
    @State private var flowingTrackOffset: CGFloat = -180
    @State private var showLandingSpark: Bool = false
    
    public init(source: MusicProviderType, destination: MusicProviderType) {
        self.source = source
        self.destination = destination
    }
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MIGRATION STREAM")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text("Live Bridge Flow")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(PastelTheme.cardBorder)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                // MARK: - Dual Platform Source & Destination Hub
                HStack(spacing: 16) {
                    // Left Source Hub
                    ServiceHubNode(
                        type: source,
                        label: "Source",
                        isSource: true
                    )
                    
                    // Center Animated Arrows & Flow Pipe
                    VStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(PastelTheme.pastelOat)
                            .offset(x: streamPhase * 6)
                        
                        Text("\(Int(transferManager.progress * 100))%")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                    }
                    .frame(width: 50)
                    
                    // Right Destination Hub
                    ServiceHubNode(
                        type: destination,
                        label: "Target",
                        isSource: false
                    )
                }
                .padding(.horizontal, 20)
                
                // MARK: - Flow Stream Canvas (Songs floating across)
                ZStack {
                    // River bed background
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(PastelTheme.card)
                        .frame(height: 220)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(PastelTheme.cardBorder, lineWidth: 1)
                        )
                    
                    // Flowing stream guide line
                    Path { path in
                        path.move(to: CGPoint(x: 30, y: 110))
                        path.addCurve(
                            to: CGPoint(x: 330, y: 110),
                            control1: CGPoint(x: 120, y: 70),
                            control2: CGPoint(x: 240, y: 150)
                        )
                    }
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color(hex: source.brandColorHex).opacity(0.4),
                                PastelTheme.emeraldSuccess.opacity(0.7),
                                Color(hex: destination.brandColorHex).opacity(0.4)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 6], dashPhase: -streamPhase * 16)
                    )
                    .frame(height: 220)
                    
                    // The Flowing Track Capsule
                    HStack(spacing: 8) {
                        Image(systemName: "music.note")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(transferManager.currentTrackTitle.isEmpty ? "Starboy" : transferManager.currentTrackTitle)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                                .lineLimit(1)
                            
                            Text(transferManager.currentTrackArtist.isEmpty ? "The Weeknd" : transferManager.currentTrackArtist)
                                .font(.system(size: 11))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineLimit(1)
                        }
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(PastelTheme.cardBorderFocused, lineWidth: 1))
                    .shadow(color: PastelTheme.emeraldSuccess.opacity(0.2), radius: 8)
                    .offset(x: flowingTrackOffset)
                    
                    // Target Landing Spark
                    if showLandingSpark {
                        Circle()
                            .fill(PastelTheme.emeraldSuccess)
                            .frame(width: 24, height: 24)
                            .blur(radius: 4)
                            .offset(x: 130)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: - Live Metrics HUD Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("TRANSFERRED")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textTertiary)
                            Text("\(transferManager.processedCount) of \(max(1, transferManager.totalToProcess)) tracks")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                                .monospacedDigit()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("PRECISION")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textTertiary)
                            Text("ISRC Exact Match")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.emeraldSuccess)
                        }
                    }
                    
                    // 3D Liquid Wave Progress Bar
                    LiquidWaveProgressView(
                        progress: transferManager.progress,
                        color: PastelTheme.emeraldSuccess,
                        secondaryColor: PastelTheme.pastelOat
                    )
                    .frame(height: 18)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.8))
                }
                .padding(16)
                .background(PastelTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(PastelTheme.cardBorder, lineWidth: 1))
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Done / Dismiss Button
                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PastelTheme.pastelOat)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(TouchFeedbackButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            startFlowAnimation()
        }
    }
    
    private func startFlowAnimation() {
        // Continuous dash stream
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            streamPhase = 1.0
        }
        
        // Track capsule crossing cycle
        animateTrackCrossing()
    }
    
    private func animateTrackCrossing() {
        flowingTrackOffset = -130
        showLandingSpark = false
        
        withAnimation(.easeInOut(duration: 2.2)) {
            flowingTrackOffset = 130
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.1) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                showLandingSpark = true
            }
            HapticManager.lightImpact()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                animateTrackCrossing()
            }
        }
    }
}

// MARK: - Service Hub Node
private struct ServiceHubNode: View {
    let type: MusicProviderType
    let label: String
    let isSource: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textTertiary)
            
            ZStack {
                Circle()
                    .fill(PastelTheme.card)
                    .frame(width: 68, height: 68)
                    .overlay(
                        Circle().stroke(Color(hex: type.brandColorHex).opacity(0.4), lineWidth: 1.5)
                    )
                
                Image(systemName: type.iconName)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color(hex: type.brandColorHex))
            }
            
            Text(type.displayName)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(PastelTheme.cardSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}
