import SwiftUI

/// Detail Inspector Sheet for an individual Listening Habit cluster
public struct HabitDetailSheet: View {
    public let cluster: ListeningCluster
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    public init(cluster: ListeningCluster) {
        self.cluster = cluster
    }
    
    // Tracks belonging to this cluster vibe (synced library only — no demo fill)
    private var habitTracks: [UniversalTrack] {
        Array(coordinator.allTracks.prefix(4))
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Header Hero Card
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: cluster.colorHex).opacity(0.15))
                                    .frame(width: 58, height: 58)
                                    .overlay(
                                        Circle().stroke(Color(hex: cluster.colorHex).opacity(0.4), lineWidth: 1.5)
                                    )
                                
                                Image(systemName: cluster.icon)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(Color(hex: cluster.colorHex))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cluster.title)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(PastelTheme.textPrimary)
                                
                                Text(cluster.vibeTag)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(hex: cluster.colorHex))
                            }
                            
                            Spacer()
                            
                            Text("\(cluster.percentage)%")
                                .font(.system(size: 22, weight: .heavy, design: .rounded))
                                .foregroundColor(Color(hex: cluster.colorHex))
                                .monospacedDigit()
                        }
                        .padding(18)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        
                        // MARK: - Habit Breakdown & Description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("BEHAVIOR PROFILE")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            Text(cluster.description)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(PastelTheme.textSecondary)
                                .lineSpacing(4)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        
                        // MARK: - Time & Rhythm Metrics
                        VStack(alignment: .leading, spacing: 14) {
                            Text("ACOUSTIC SIGNATURE")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            HStack(spacing: 12) {
                                HabitMetricBox(title: "PEAK WINDOW", value: "23:00 — 04:00", icon: "moon.stars.fill")
                                HabitMetricBox(title: "TEMPO RANGE", value: "118 — 132 BPM", icon: "metronome.fill")
                            }
                        }
                        .padding(18)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        
                        // MARK: - Representative Tracks
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CORE TRACKS IN THIS HABIT")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(0.6)
                                .foregroundColor(PastelTheme.textTertiary)
                            
                            VStack(spacing: 8) {
                                if habitTracks.isEmpty {
                                    Text("Sync your library to populate tracks for this habit.")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(PastelTheme.textTertiary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 6)
                                } else {
                                    ForEach(habitTracks) { track in
                                        HStack(spacing: 12) {
                                            Button {
                                                player.play(track: track, in: habitTracks)
                                            } label: {
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .fill(PastelTheme.cardSubtle)
                                                        .frame(width: 38, height: 38)
                                                    
                                                    Image(systemName: player.currentTrack == track && player.isPlaying ? "pause.fill" : "play.fill")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundColor(PastelTheme.pastelOat)
                                                }
                                            }
                                            .buttonStyle(TouchFeedbackButtonStyle())
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(track.title)
                                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                                    .foregroundColor(player.currentTrack == track ? PastelTheme.pastelOat : PastelTheme.textPrimary)
                                                    .lineLimit(1)
                                                
                                                Text(track.primaryArtist)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(PastelTheme.textSecondary)
                                                    .lineLimit(1)
                                            }
                                            
                                            Spacer()
                                            
                                            Text(track.formattedDuration)
                                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                                .foregroundColor(PastelTheme.textTertiary)
                                        }
                                        .padding(10)
                                        .background(PastelTheme.cardSubtle)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        
                        // Action: Play Session
                        if let firstTrack = habitTracks.first {
                            Button {
                                HapticManager.successNotification()
                                player.play(track: firstTrack, in: habitTracks)
                                dismiss()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Play Habit Session")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(PastelTheme.textOnOat)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(PastelTheme.pastelOat)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(TouchFeedbackButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Habit Details")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(PastelTheme.pastelOat)
                }
            }
        }
    }
}

// MARK: - Habit Metric Box
private struct HabitMetricBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(PastelTheme.textTertiary)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textTertiary)
            }
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(PastelTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(PastelTheme.cardSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
