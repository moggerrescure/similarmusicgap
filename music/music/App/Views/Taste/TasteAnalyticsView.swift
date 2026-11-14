import SwiftUI

/// Screen: Taste Analytics & Acoustic Profile
public struct TasteAnalyticsView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @State private var profile: FullTasteProfile = TasteAnalyticsEngine.shared.analyzeLibrary(tracks: ServicesCoordinator.shared.allTracks)
    @State private var showingStorySheet: Bool = false
    @State private var generatedStoryImage: PlatformImage?
    @State private var showingShareSheet: Bool = false
    @State private var selectedCluster: ListeningCluster? = nil
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AmbientWashBackgroundView()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Archetype Insight Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("LIBRARY ARCHETYPE")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text(profile.archetypeTitle)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        
                        Text(profile.aiInterpretation)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(PastelTheme.textSecondary)
                            .lineSpacing(4)
                            .padding(.top, 2)
                        
                        Text("On-device summary from your synced library — not an AI model.")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(PastelTheme.textTertiary)
                            .padding(.top, 4)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Acoustic Spectrum (heuristic from library shape — not Spotify audio features)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DERIVED SPECTRUM")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text("Heuristic from your library shape — not official Spotify audio features.")
                            .font(.system(size: 11))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        VStack(spacing: 12) {
                            AcousticMetricRow(
                                title: "Energy",
                                value: profile.acousticProfile.energy,
                                icon: "bolt.fill",
                                color: PastelTheme.pastelOat
                            )
                            
                            AcousticMetricRow(
                                title: "Valence",
                                value: profile.acousticProfile.valence,
                                icon: "sun.max.fill",
                                color: PastelTheme.amberWarning
                            )
                            
                            AcousticMetricRow(
                                title: "Danceability",
                                value: profile.acousticProfile.danceability,
                                icon: "music.note",
                                color: PastelTheme.emeraldSuccess
                            )
                            
                            AcousticMetricRow(
                                title: "Acousticness",
                                value: profile.acousticProfile.acousticness,
                                icon: "guitars.fill",
                                color: PastelTheme.slateBlue
                            )
                            
                            AcousticMetricRow(
                                title: "Focus & Flow",
                                value: profile.acousticProfile.focusFlow,
                                icon: "waveform.badge.magnifyingglass",
                                color: PastelTheme.lavenderAI
                            )
                        }
                        
                        if profile.totalAnalyzedTracks > 0 {
                            TasteRadarView(profile: profile.acousticProfile)
                                .frame(height: 220)
                                .padding(.top, 8)
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Decade Affinity Distribution
                    VStack(alignment: .leading, spacing: 14) {
                        Text("DECADE DISTRIBUTION")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        // Stacked horizontal capsule
                        GeometryReader { geo in
                            HStack(spacing: 2) {
                                ForEach(profile.decadeDistribution) { dec in
                                    Rectangle()
                                        .fill(Color(hex: dec.colorHex))
                                        .frame(width: geo.size.width * CGFloat(dec.percentage / 100.0))
                                }
                            }
                            .clipShape(Capsule())
                        }
                        .frame(height: 8)
                        
                        // Legend
                        HStack {
                            ForEach(profile.decadeDistribution) { dec in
                                HStack(spacing: 4) {
                                    Text(dec.decade)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(PastelTheme.textSecondary)
                                    Text("\(Int(dec.percentage))%")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(hex: dec.colorHex))
                                }
                                if dec.decade != profile.decadeDistribution.last?.decade {
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Listening Habits / Clusters
                    VStack(alignment: .leading, spacing: 12) {
                        Text("LISTENING HABITS")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(0.6)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        ForEach(profile.clusters) { cluster in
                            Button {
                                HapticManager.lightImpact()
                                selectedCluster = cluster
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: cluster.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(Color(hex: cluster.colorHex))
                                        .frame(width: 32, height: 32)
                                        .background(PastelTheme.cardSubtle)
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(cluster.title)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(PastelTheme.textPrimary)
                                            Spacer()
                                            Text("\(cluster.percentage)%")
                                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                                .foregroundColor(Color(hex: cluster.colorHex))
                                        }
                                        Text(cluster.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(PastelTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(PastelTheme.textTertiary)
                                }
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            if cluster.id != profile.clusters.last?.id {
                                Divider().background(PastelTheme.cardBorder)
                            }
                        }
                    }
                    .padding(18)
                    .background(PastelTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(PastelTheme.cardBorder, lineWidth: 1)
                    )
                    
                    // MARK: - Share Action
                    Button {
                        HapticManager.successNotification()
                        showingStorySheet = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Share Stories Card")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(PastelTheme.textOnOat)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(PastelTheme.pastelOat)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(TouchFeedbackButtonStyle())
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Taste Profile")
        .inlineNavigationBarTitle()
        .onAppear { refreshProfile() }
        .onChange(of: coordinator.allTracks.count) { _, _ in
            refreshProfile()
        }
        .onChange(of: coordinator.lastSyncAt) { _, _ in
            refreshProfile()
        }
        .sheet(isPresented: $showingStorySheet) {
            StoryPreviewModal(profile: profile)
        }
        .sheet(item: $selectedCluster) { cluster in
            HabitDetailSheet(cluster: cluster)
        }
    }
    
    private func refreshProfile() {
        profile = TasteAnalyticsEngine.shared.analyzeLibrary(tracks: coordinator.allTracks)
    }
}

// MARK: - Acoustic Metric Row Component (Apple Health HUD Style)
private struct AcousticMetricRow: View {
    let title: String
    let value: Double // 0.0 to 1.0
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 18)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(PastelTheme.textPrimary)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            
            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PastelTheme.cardSubtle)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.0, value))), height: 6)
                }
            }
            .frame(height: 6)
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
                    
                    HStack(spacing: 12) {
                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(PastelTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(PastelTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            .frame(height: 48)
                            .background(PastelTheme.pastelOat)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

#if DEBUG
struct TasteAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TasteAnalyticsView()
        }
    }
}
#endif
