import Foundation

/// Persists transfer execution reports across launches.
public enum TransferHistoryStore {
    private static let fileName = "soundshift_transfer_history.json"
    
    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = dir.appendingPathComponent("SoundShift", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent(fileName)
    }
    
    public static func load() -> [TransferExecutionReport] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TransferExecutionReport].self, from: data)) ?? []
    }
    
    public static func save(_ history: [TransferExecutionReport]) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Array(history.prefix(50))) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
