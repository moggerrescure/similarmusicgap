import SwiftUI

/// 9:16 Viral Instagram Stories & Telegram Taste Passport Card (P1 - SO1)
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
            
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header Receipt Bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SOUNDSHIFT // SONIC PASSPORT")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .tracking(1.5)
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text("CROSS-PLATFORM AUDIT")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(1.0)
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
                VStack(alignment: .leading, spacing: 6) {
                    Text("ARCHETYPE")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(PastelTheme.amberWarning)
                    
                    Text(profile.archetypeTitle)
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                        .lineLimit(2)
                }
                
                // MARK: - Mini Radar Chart
                TasteRadarView(profile: profile.acousticProfile)
                    .frame(height: 190)
                
                // MARK: - Top 3 Key Artists
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFINING ARTISTS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(1.0)
                        .foregroundColor(PastelTheme.textTertiary)
                    
                    HStack(spacing: 8) {
                        ForEach(profile.topArtists.prefix(3), id: \.self) { artist in
                            Text(artist)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.pastelOat)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(PastelTheme.card)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                        }
                    }
                }
                
                // MARK: - Taste Twin Metric (SO3)
                HStack(spacing: 12) {
                    Circle()
                        .fill(PastelTheme.emeraldSuccess)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ANONYMOUS TASTE TWIN")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textTertiary)
                        
                        Text("98.4% Match in \(profile.tasteTwin.twinLocationHint)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                    }
                    
                    Spacer()
                    
                    Text("Top 0.04%")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(PastelTheme.amberWarning)
                }
                .padding(12)
                .background(PastelTheme.cardSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(PastelTheme.cardBorder, lineWidth: 0.5)
                )
                
                Spacer()
                
                // MARK: - Footer Brand Stamp
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PastelTheme.pastelOat)
                        Text("SoundShift")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(PastelTheme.pastelOat)
                    }
                    
                    Spacer()
                    
                    Text("soundshift.app // YM • Spotify • AM")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(PastelTheme.textTertiary)
                }
            }
            .padding(26)
        }
        .frame(width: 360, height: 640) // 9:16 aspect canvas
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(PastelTheme.cardBorderFocused, lineWidth: 1.5)
        )
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

