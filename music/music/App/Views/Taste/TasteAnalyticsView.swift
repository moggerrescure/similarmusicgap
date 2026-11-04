import SwiftUI

/// Screen: Taste Analytics & Social Music DNA Hub (P0 - S1, S2, S3, SO1, SO3)
public struct TasteAnalyticsView: View {
    @State private var profile: FullTasteProfile = TasteAnalyticsEngine.shared.analyzeLibrary(tracks: ServicesCoordinator.shared.allTracks)
    @State private var showingStorySheet: Bool = false
    @State private var generatedStoryImage: PlatformImage?
    @State private var showingShareSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            PastelTheme.canvas
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Circle()
                                .fill(PastelTheme.lavenderAI)
                                .frame(width: 8, height: 8)
                            
                            Text("AI TASTE INTELLIGENCE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundColor(PastelTheme.lavenderAI)
                        }
                        
                        Text(profile.archetypeTitle)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                    }
                    .padding(.top, 8)
                    
                    // MARK: - AI Narrative Quote
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(PastelTheme.pastelOat)
                            Text("PORTRAIT OF YOUR TASTE")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .tracking(0.8)
                                .foregroundColor(PastelTheme.pastelOat)
                        }
                        
                        Text(profile.aiInterpretation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(PastelTheme.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Acoustic Radar (S1)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("ACOUSTIC DIMENSIONS (S1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        TasteRadarView(profile: profile.acousticProfile)
                            .padding(.vertical, 8)
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Decade Affinity Distribution (S2)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DECADE AFFINITY (S2)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        // Horizontal Bar
                        GeometryReader { geo in
                            HStack(spacing: 3) {
                                ForEach(profile.decadeDistribution) { dec in
                                    Rectangle()
                                        .fill(Color(hex: dec.colorHex))
                                        .frame(width: geo.size.width * CGFloat(dec.percentage / 100.0))
                                }
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 10)
                        
                        // Decade Legend
                        HStack {
                            ForEach(profile.decadeDistribution) { dec in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: dec.colorHex))
                                        .frame(width: 6, height: 6)
                                    Text("\(dec.decade) (\(Int(dec.percentage))%)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(PastelTheme.textSecondary)
                                }
                                if dec.decade != profile.decadeDistribution.last?.decade {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Context / Mode Clusters (S3)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CONTEXT CLUSTERS (S3)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.0)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        ForEach(profile.clusters) { cluster in
                            HStack(spacing: 14) {
                                Circle()
                                    .fill(PastelTheme.cardSubtle)
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        Image(systemName: cluster.icon)
                                            .foregroundColor(Color(hex: cluster.colorHex))
                                    )
                                
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(cluster.title)
                                            .font(.system(size: 15, weight: .bold, design: .rounded))
                                            .foregroundColor(PastelTheme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Text("\(cluster.percentage)%")
                                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                                            .foregroundColor(Color(hex: cluster.colorHex))
                                    }
                                    
                                    Text(cluster.description)
                                        .font(.system(size: 12))
                                        .foregroundColor(PastelTheme.textSecondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(14)
                            .background(PastelTheme.cardSubtle)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Primary Action: Generate Social Story Card (SO1)
                    Button {
                        HapticManager.successNotification()
                        showingStorySheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "sparkles.rectangle.stack.fill")
                                .font(.system(size: 18))
                            Text("Generate 9:16 Social Story Card (SO1)")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(PastelTheme.pastelOat)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Taste DNA")
        .inlineNavigationBarTitle()
        .sheet(isPresented: $showingStorySheet) {
            StoryPreviewModal(profile: profile)
        }
    }
}

// MARK: - Story Preview Modal Sheet
private struct StoryPreviewModal: View {
    let profile: FullTasteProfile
    @Environment(\.dismiss) private var dismiss
    @State private var renderedImage: PlatformImage?
    @State private var showingShareSheet: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    TasteCardStoryView(profile: profile)
                        .scaleEffect(0.85)
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 14) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(PastelTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        
                        Button {
                            HapticManager.successNotification()
                            if let img = StoryExporter.renderStoryImage(profile: profile) {
                                self.renderedImage = img
                                self.showingShareSheet = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share to Stories")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(PastelTheme.textOnOat)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(PastelTheme.pastelOat)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(TouchFeedbackButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Stories Card")
            .inlineNavigationBarTitle()
            .sheet(isPresented: $showingShareSheet) {
                if let renderedImage = renderedImage {
                    ShareImageSheet(image: renderedImage)
                }
            }
        }
    }
}

#if os(iOS)
private struct ShareImageSheet: UIViewControllerRepresentable {
    let image: UIImage
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#else
private struct ShareImageSheet: View {
    let image: PlatformImage
    var body: some View { Text("Share Image") }
}
#endif

#Preview {
    NavigationStack {
        TasteAnalyticsView()
    }
}

