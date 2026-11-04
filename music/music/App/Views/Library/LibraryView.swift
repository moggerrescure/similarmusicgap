import SwiftUI

/// Screen: Unified Cross-Service Library & Instant Offline Search (P0 - L1, L2, L3, L5, L6)
public struct LibraryView: View {
    @ObservedObject private var coordinator = ServicesCoordinator.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: LibraryFilter = .all
    @State private var showingDuplicatesSheet: Bool = false
    
    // Sample demo tracks if coordinator is empty
    private var allTracks: [UniversalTrack] {
        if coordinator.allTracks.isEmpty {
            return [
                UniversalTrack(isrc: "USUM71703861", title: "Starboy", artists: ["The Weeknd", "Daft Punk"], album: "Starboy", durationMs: 230453, yandexId: "29871638", spotifyId: "7a26vX02Y4vYj9P6RrqU04"),
                UniversalTrack(isrc: "GBUM71505080", title: "The Less I Know the Better", artists: ["Tame Impala"], album: "Currents", durationMs: 216320, spotifyId: "6K4t31amVTKVgPeRoxXErq"),
                UniversalTrack(isrc: "USAT21900122", title: "Blinding Lights", artists: ["The Weeknd"], album: "After Hours", durationMs: 200040, appleMusicId: "1499378607"),
                UniversalTrack(isrc: "RUAA12000042", title: "Где нас нет", artists: ["Oxxxymiron"], album: "ГОРГОРОД", durationMs: 265000, yandexId: "24981120"),
                UniversalTrack(isrc: "FRUM71300088", title: "Instant Crush", artists: ["Daft Punk", "Julian Casablancas"], album: "Random Access Memories", durationMs: 337560, yandexId: "14589231", spotifyId: "2bpgKp31sOVoTeStOXzi8C"),
                UniversalTrack(isrc: "USWB11200021", title: "Midnight City", artists: ["M83"], album: "Hurry Up, We're Dreaming", durationMs: 243000, spotifyId: "1eyzqe2QqGZUmfcPZtrIyt", appleMusicId: "466487841")
            ]
        }
        return coordinator.allTracks
    }
    
    private var duplicates: [DuplicateGroup] {
        DuplicatesEngine.shared.findDuplicates(in: allTracks)
    }
    
    private var filteredTracks: [UniversalTrack] {
        var list = allTracks
        
        // Filter by platform
        switch selectedFilter {
        case .all:
            break
        case .yandexMusic:
            list = list.filter { $0.yandexId != nil }
        case .spotify:
            list = list.filter { $0.spotifyId != nil }
        case .appleMusic:
            list = list.filter { $0.appleMusicId != nil }
        case .duplicates:
            let dupKeys = Set(duplicates.map { $0.canonicalTitle })
            list = list.filter { dupKeys.contains($0.title) }
        }
        
        // Search text filter (L2)
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            list = list.filter {
                $0.title.lowercased().contains(query) ||
                $0.primaryArtist.lowercased().contains(query) ||
                ($0.album?.lowercased().contains(query) ?? false)
            }
        }
        return list
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                PastelTheme.canvas
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - Filter Chip Strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(title: "All (\(allTracks.count))", isSelected: selectedFilter == .all) {
                                selectedFilter = .all
                            }
                            
                            if !duplicates.isEmpty {
                                FilterChip(
                                    title: "\(duplicates.count) Duplicates (L5)",
                                    isSelected: selectedFilter == .duplicates,
                                    badgeColor: PastelTheme.amberWarning
                                ) {
                                    selectedFilter = .duplicates
                                }
                            }
                            
                            FilterChip(title: "Spotify", isSelected: selectedFilter == .spotify, badgeColor: PastelTheme.emeraldSuccess) {
                                selectedFilter = .spotify
                            }
                            
                            FilterChip(title: "Apple Music", isSelected: selectedFilter == .appleMusic, badgeColor: Color(hex: "#FB7185")) {
                                selectedFilter = .appleMusic
                            }
                            
                            FilterChip(title: "Yandex Music", isSelected: selectedFilter == .yandexMusic, badgeColor: PastelTheme.amberWarning) {
                                selectedFilter = .yandexMusic
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    
                    // MARK: - Duplicates Banner Alert (L5)
                    if selectedFilter == .duplicates && !duplicates.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(PastelTheme.amberWarning)
                            Text("\(duplicates.count) cross-service duplicates found.")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textPrimary)
                            Spacer()
                            Button("Inspect") {
                                showingDuplicatesSheet = true
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(PastelTheme.pastelOat)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(PastelTheme.cardSubtle)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PastelTheme.amberWarning.opacity(0.3), lineWidth: 1))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                    
                    // MARK: - Track List (L1)
                    if filteredTracks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 40))
                                .foregroundColor(PastelTheme.textTertiary)
                            Text("No tracks found")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTracks) { track in
                                TrackRow(track: track)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Universal Library (L1)")
            .inlineNavigationBarTitle()
            .searchable(text: $searchText, prompt: "Search title, artist, or album (L2)")
            .sheet(isPresented: $showingDuplicatesSheet) {
                DuplicatesInspectorView(duplicates: duplicates)
            }
        }
    }
}

// MARK: - Track Row Component
private struct TrackRow: View {
    let track: UniversalTrack
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon Placeholder with Service Tone
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(PastelTheme.cardSubtle)
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(PastelTheme.pastelOat)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(PastelTheme.textPrimary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(track.primaryArtist)
                        .foregroundColor(PastelTheme.textSecondary)
                    if let album = track.album {
                        Text("•")
                            .foregroundColor(PastelTheme.textTertiary)
                        Text(album)
                            .foregroundColor(PastelTheme.textTertiary)
                            .lineLimit(1)
                    }
                }
                .font(.system(size: 12))
            }
            
            Spacer()
            
            // Available Platforms Indicator Pills & Deep Links (L6)
            HStack(spacing: 6) {
                if track.yandexId != nil {
                    Button {
                        DeepLinkManager.openTrack(track: track, in: .yandexMusic)
                    } label: {
                        Circle()
                            .fill(PastelTheme.amberWarning)
                            .frame(width: 8, height: 8)
                    }
                }
                if track.spotifyId != nil {
                    Button {
                        DeepLinkManager.openTrack(track: track, in: .spotify)
                    } label: {
                        Circle()
                            .fill(PastelTheme.emeraldSuccess)
                            .frame(width: 8, height: 8)
                    }
                }
                if track.appleMusicId != nil {
                    Button {
                        DeepLinkManager.openTrack(track: track, in: .appleMusic)
                    } label: {
                        Circle()
                            .fill(Color(hex: "#FB7185"))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(track.formattedDuration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(PastelTheme.textTertiary)
                    .padding(.leading, 4)
            }
        }
        .padding(12)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
        )
        .contextMenu {
            if track.spotifyId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .spotify) } label: {
                    Label("Open in Spotify (L6)", systemImage: "arrow.up.right")
                }
            }
            if track.appleMusicId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .appleMusic) } label: {
                    Label("Open in Apple Music (L6)", systemImage: "arrow.up.right")
                }
            }
            if track.yandexId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .yandexMusic) } label: {
                    Label("Open in Yandex Music (L6)", systemImage: "arrow.up.right")
                }
            }
        }
    }
}

// MARK: - Filter Chip Component
private enum LibraryFilter {
    case all, yandexMusic, spotify, appleMusic, duplicates
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var badgeColor: Color? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            HStack(spacing: 6) {
                if let color = badgeColor {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? PastelTheme.pastelOat : PastelTheme.card)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.clear : PastelTheme.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
}

#Preview {
    LibraryView()
}

