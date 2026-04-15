import Foundation

/// Persists saved clips to disk as JSON
final class StorageManager {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Copyaster", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("saved.json")
    }

    func loadSaved() -> [ClipboardItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("[Copyaster] Error cargando guardados: \(error)")
            return []
        }
    }

    func saveToDisk(_ items: [ClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[Copyaster] Error guardando: \(error)")
        }
    }
}
