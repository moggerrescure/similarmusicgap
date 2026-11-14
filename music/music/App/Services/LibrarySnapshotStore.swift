import Foundation

/// On-device JSON snapshot of the synced universal library (survives app relaunch).
public enum LibrarySnapshotStore {
    private static let fileName = "soundshift_library_snapshot.json"
    
    private struct Payload: Codable {
        let savedAt: Date
        let tracks: [UniversalTrack]
        let playlists: [UniversalPlaylist]
    }
    
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = dir.appendingPathComponent("SoundShift", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }
    
    public static func load() -> (tracks: [UniversalTrack], playlists: [UniversalPlaylist], savedAt: Date?) {
        guard let data = try? Data(contentsOf: fileURL) else {
            return ([], [], nil)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Payload.self, from: data) else {
            return ([], [], nil)
        }
        return (payload.tracks, payload.playlists, payload.savedAt)
    }
    
    public static func save(tracks: [UniversalTrack], playlists: [UniversalPlaylist]) {
        let payload = Payload(savedAt: Date(), tracks: tracks, playlists: playlists)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
    
    public static func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
