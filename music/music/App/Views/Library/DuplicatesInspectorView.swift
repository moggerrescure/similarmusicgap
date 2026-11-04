import SwiftUI

/// Inspector Sheet for Cross-Platform Duplicate Tracks (P2 - L5)
public struct DuplicatesInspectorView: View {
    public let duplicates: [DuplicateGroup]
    @Environment(\.dismiss) private var dismiss
    
    public init(duplicates: [DuplicateGroup]) {
        self.duplicates = duplicates
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                if duplicates.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundColor(PastelTheme.emeraldSuccess)
                        Text("No Duplicates Found")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(PastelTheme.textPrimary)
                        Text("Your library is 100% clean across all connected platforms.")
                            .font(.system(size: 14))
                            .foregroundColor(PastelTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(duplicates) { dup in
                                DuplicateRowCard(item: dup)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Duplicates Finder (L5)")
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

// MARK: - Duplicate Row Card
private struct DuplicateRowCard: View {
    let item: DuplicateGroup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.canonicalTitle)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(PastelTheme.textPrimary)
                    Text(item.canonicalArtist)
                        .font(.system(size: 13))
                        .foregroundColor(PastelTheme.textSecondary)
                }
                
                Spacer()
                
                Text("\(item.tracks.count) Copies")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(PastelTheme.amberWarning)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(PastelTheme.cardSubtle)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.5))
            }
            
            Divider()
                .background(PastelTheme.cardBorder)
            
            // Connected Services Badges & Direct Deep Links (L6)
            HStack(spacing: 8) {
                Text("Found in:")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(PastelTheme.textTertiary)
                
                ForEach(item.services) { srv in
                    Button {
                        HapticManager.lightImpact()
                        if let track = item.tracks.first(where: {
                            (srv == .yandexMusic && $0.yandexId != nil) ||
                            (srv == .spotify && $0.spotifyId != nil) ||
                            (srv == .appleMusic && $0.appleMusicId != nil)
                        }) {
                            DeepLinkManager.openTrack(track: track, in: srv)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: srv.brandColorHex))
                                .frame(width: 6, height: 6)
                            Text(srv.displayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(PastelTheme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(PastelTheme.cardBorder, lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(16)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 1)
        )
    }
}

