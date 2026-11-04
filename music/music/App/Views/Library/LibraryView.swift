import SwiftUI

/// Screen: Unified Cross-Service Library & Instant Search
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
                                    title: "Duplicates (\(duplicates.count))",
                                    isSelected: selectedFilter == .duplicates
                                ) {
                                    selectedFilter = .duplicates
                                }
                            }
                            
                            FilterChip(title: "Spotify", isSelected: selectedFilter == .spotify) {
                                selectedFilter = .spotify
                            }
                            
                            FilterChip(title: "Apple Music", isSelected: selectedFilter == .appleMusic) {
                                selectedFilter = .appleMusic
                            }
                            
                            FilterChip(title: "Yandex Music", isSelected: selectedFilter == .yandexMusic) {
                                selectedFilter = .yandexMusic
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                    
                    // MARK: - Duplicates Banner
                    if selectedFilter == .duplicates && !duplicates.isEmpty {
                        HStack {
                            Image(systemName: "square.stack.3d.down.right.fill")
                                .foregroundColor(PastelTheme.amberWarning)
                            Text("\(duplicates.count) cross-library duplicates found")
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
                        .background(PastelTheme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(PastelTheme.cardBorder, lineWidth: 1))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                    }
                    
                    // MARK: - Track List
                    if filteredTracks.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(PastelTheme.textTertiary)
                            Text("No tracks found")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(PastelTheme.textSecondary)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredTracks) { track in
                                TrackRow(track: track)
                                    .listRowBackground(Color.clear)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowSeparator(.hidden)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Library")
            .inlineNavigationBarTitle()
            .searchable(text: $searchText, prompt: "Search songs, artists, albums")
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
        HStack(spacing: 12) {
            // Artwork placeholder
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PastelTheme.cardSubtle)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 16))
                        .foregroundColor(PastelTheme.pastelOat)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
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
            
            // Platform Badges & Duration
            HStack(spacing: 6) {
                if track.spotifyId != nil {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#10B981"))
                }
                if track.appleMusicId != nil {
                    Image(systemName: "applelogo")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#FB7185"))
                }
                if track.yandexId != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#FBBF24"))
                }
                
                Text(track.formattedDuration)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(PastelTheme.textTertiary)
                    .padding(.leading, 2)
            }
        }
        .padding(12)
        .background(PastelTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(PastelTheme.cardBorder, lineWidth: 0.8)
        )
        .contextMenu {
            if track.spotifyId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .spotify) } label: {
                    Label("Open in Spotify", systemImage: "arrow.up.right")
                }
            }
            if track.appleMusicId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .appleMusic) } label: {
                    Label("Open in Apple Music", systemImage: "arrow.up.right")
                }
            }
            if track.yandexId != nil {
                Button { DeepLinkManager.openTrack(track: track, in: .yandexMusic) } label: {
                    Label("Open in Yandex Music", systemImage: "arrow.up.right")
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
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.lightImpact()
            action()
        }) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? PastelTheme.textOnOat : PastelTheme.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? PastelTheme.pastelOat : PastelTheme.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : PastelTheme.cardBorder, lineWidth: 0.8)
                )
        }
        .buttonStyle(TouchFeedbackButtonStyle())
    }
}

#Preview {
    LibraryView()
}
