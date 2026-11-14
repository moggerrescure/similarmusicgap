import SwiftUI

/// 9:16 Viral Instagram Stories & Telegram Taste Passport Card
public struct TasteCardStoryView: View {
    public let profile: FullTasteProfile
    
    public init(profile: FullTasteProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        ZStack {
            // Background Luxury Cashmere Canvas
            PastelTheme.canvas
            
            // Subtle Radial Ambient Glow
            RadialGradient(
                colors: [PastelTheme.lavenderAI.opacity(0.12), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 400
            )
            
            VStack(alignment: .leading, spacing: 18) {
                // MARK: - Header Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOUNDSHIFT // SONIC PASSPORT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .tracking(1.2)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text("CROSS-LIBRARY AUDIT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(PastelTheme.emeraldSuccess)
                    }
                    
                    Spacer()
                    
                    Text("\(profile.totalAnalyzedTracks) TRACKS")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                        .foregroundColor(PastelTheme.pastelOat)
                }
                
                Divider()
                    .background(PastelTheme.cardBorder)
                
                // MARK: - Archetype Hero
                VStack(alignment: .leading, spacing: 4) {
                    Text("ARCHETYPE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(PastelTheme.amberWarning)
                    
                    Text(profile.archetypeTitle)
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .lineLimit(2)
                }
                
                // MARK: - Acoustic Spectrum Bars
                VStack(spacing: 8) {
                    StoryAcousticBar(title: "ENERGY", value: profile.acousticProfile.energy, color: PastelTheme.pastelOat)
                    StoryAcousticBar(title: "VALENCE", value: profile.acousticProfile.valence, color: PastelTheme.amberWarning)
                    StoryAcousticBar(title: "DANCEABILITY", value: profile.acousticProfile.danceability, color: PastelTheme.emeraldSuccess)
                    StoryAcousticBar(title: "ACOUSTICNESS", value: profile.acousticProfile.acousticness, color: PastelTheme.slateBlue)
                }
                .padding(14)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                
                // MARK: - Top Key Artists
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFINING ARTISTS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    HStack(spacing: 6) {
                        ForEach(profile.topArtists.prefix(3), id: \.self) { artist in
                            Text(artist)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(PastelTheme.card)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                        }
                    }
                }
                
                // MARK: - Library shape (honest — not a fabricated twin %)
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(PastelTheme.emeraldSuccess)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LIBRARY SHAPE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text(profile.tasteTwin.twinLocationHint)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    if !profile.tasteTwin.sharedNicheArtists.isEmpty {
                        Text(profile.tasteTwin.sharedNicheArtists.prefix(2).joined(separator: " · "))
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(PastelTheme.amberWarning)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100, alignment: .trailing)
                    }
                }
                .padding(12)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 0.5)
                )
                
                Spacer()
                
                // MARK: - Footer Brand Stamp
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(PastelTheme.pastelOat)
                        Text("SoundShift")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                    
                    Spacer()
                    
                    Text("soundshift.app")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(PastelTheme.textTertiary)
                }
            }
            .padding(24)
        }
        .frame(width: 360, height: 640) // 9:16 aspect canvas
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1.5)
        )
    }
}

// MARK: - Story Acoustic Bar
private struct StoryAcousticBar: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textSecondary)
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(PastelTheme.card)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(min(1.0, max(0.0, value))))
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Image Snapshot Render Helper
@MainActor
public enum StoryExporter {
    public static func renderStoryImage(profile: FullTasteProfile) -> PlatformImage? {
        #if os(iOS)
        let storyView = TasteCardStoryView(profile: profile)
        let renderer = ImageRenderer(content: storyView)
        renderer.scale = 3.0 // 3x Retina output (1080x1920)
        return renderer.uiImage
        #elseif os(macOS)
        let storyView = TasteCardStoryView(profile: profile)
        let renderer = ImageRenderer(content: storyView)
        renderer.scale = 2.0
        return renderer.nsImage
        #else
        return nil
        #endif
    }
}
