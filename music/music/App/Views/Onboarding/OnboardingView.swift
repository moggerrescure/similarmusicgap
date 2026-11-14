import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var currentSlideIndex: Int = 0
    @State private var isCompleted: Bool = false
    
    private let slides = OnboardingSlide.slides
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // MARK: - Layer 0: Atmospheric fallback (videos are optional in the bundle)
            AmbientWashBackgroundView(tab: .home)
                .ignoresSafeArea()
            
            // MARK: - Layer 1: Seamless Looping Video Background (no-op if mp4 missing)
            LooperVideoPlayerView(videoName: slides[currentSlideIndex].videoResourceName)
                .id(slides[currentSlideIndex].videoResourceName)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.45), value: currentSlideIndex)
            
            // MARK: - Layer 2: Apple HUD Dark Scrim (PastelTheme.canvas)
            // Top shadow for status bar & badge, bottom deep gradient for readability
            VStack(spacing: 0) {
                LinearGradient(
                    stops: [
                        .init(color: PastelTheme.canvas.opacity(0.85), location: 0.0),
                        .init(color: PastelTheme.canvas.opacity(0.40), location: 0.45),
                        .init(color: .clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                
                Spacer()
                
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.0),
                        .init(color: PastelTheme.canvas.opacity(0.65), location: 0.30),
                        .init(color: PastelTheme.canvas.opacity(0.96), location: 0.75),
                        .init(color: PastelTheme.canvas, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 420)
            }
            .ignoresSafeArea()
            
            // MARK: - Layer 3: HUD Content & Interactive Controls
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack {
                    // Badge Chip
                    HStack(spacing: 6) {
                        Circle()
                            .fill(PastelTheme.emeraldSuccess)
                            .frame(width: 6, height: 6)
                        
                        Text(slides[currentSlideIndex].badgeText)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(PastelTheme.cardSubtle.opacity(0.85))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    Spacer()
                    
                    // Skip button (visible on early slides)
                    if currentSlideIndex < slides.count - 1 {
                        Button {
                            HapticManager.lightImpact()
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                currentSlideIndex = slides.count - 1
                            }
                        } label: {
                            Text("Skip")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(PastelTheme.textSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Bottom Slide Card (Editorial Typography & HUD Metrics)
                VStack(alignment: .leading, spacing: 20) {
                    // Headline
                    Text(slides[currentSlideIndex].headline)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .lineSpacing(2)
                        .minimumScaleFactor(0.85)
                    
                    // Subheadline
                    Text(slides[currentSlideIndex].subheadline)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(PastelTheme.textSecondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // HUD Glanceable Metric Pill
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(slides[currentSlideIndex].metricValue)
                                .font(.system(size: 26, weight: .heavy, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                                .monospacedDigit()
                                .contentTransition(.numericText())
                            
                            Text(slides[currentSlideIndex].metricLabel)
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(0.5)
                                .foregroundColor(PastelTheme.textTertiary)
                        }
                        
                        Spacer()
                        
                        // Service Integration Icons Hint on First Slides
                        if currentSlideIndex == 0 {
                            HStack(spacing: 8) {
                                ServiceIconCircle(symbol: "music.note", color: PastelTheme.emeraldSuccess)
                                ServiceIconCircle(symbol: "waveform", color: PastelTheme.amberWarning)
                                ServiceIconCircle(symbol: "antenna.radiowaves.left.and.right", color: PastelTheme.slateBlue)
                            }
                        }
                    }
                    .padding(16)
                    .background(PastelTheme.card.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // Pager Indicators & CTA Button
                    VStack(spacing: 16) {
                        // Custom Minimalist Pager Dots
                        HStack(spacing: 8) {
                            ForEach(0..<slides.count, id: \.self) { index in
                                Capsule()
                                    .fill(index == currentSlideIndex ? PastelTheme.pastelOat : Color.white.opacity(0.2))
                                    .frame(width: index == currentSlideIndex ? 24 : 6, height: 6)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentSlideIndex)
                            }
                            Spacer()
                        }
                        
                        // Primary CTA Button
                        Button {
                            handleNextAction()
                        } label: {
                            HStack(spacing: 10) {
                                Text(slides[currentSlideIndex].actionButtonTitle)
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                                    .foregroundColor(PastelTheme.textOnOat)
                                
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(PastelTheme.textOnOat)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(PastelTheme.pastelOat)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                        .buttonStyle(TouchFeedbackButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
    
    private func handleNextAction() {
        if currentSlideIndex < slides.count - 1 {
            HapticManager.lightImpact()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentSlideIndex += 1
            }
        } else {
            // Final Start Action → Main tabs, then open Connect
            HapticManager.successNotification()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isCompleted = true
                hasCompletedOnboarding = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                NavigationCoordinator.shared.navigateToConnect()
            }
        }
    }
}

// MARK: - Mini Icon Circle Helper
private struct ServiceIconCircle: View {
    let symbol: String
    let color: Color
    
    var body: some View {
        Circle()
            .fill(PastelTheme.cardSubtle)
            .frame(width: 36, height: 36)
            .overlay(
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
            )
            .overlay(
                Circle()
                    .stroke(PastelTheme.cardBorder, lineWidth: 0.5)
            )
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
#endif

