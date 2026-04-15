import SwiftUI

@Observable
final class AppState {

    // MARK: - Data

    var recents: [ClipboardItem] = []
    var saved: [ClipboardItem] = []

    // MARK: - UI State

    var selectedTab: Tab = .recents
    var searchText: String = ""

    enum Tab: String, CaseIterable {
        case recents = "Recientes"
        case saved = "Guardados"
    }

    // MARK: - Config

    let maxRecents = 20

    // MARK: - Filtered

    var filteredRecents: [ClipboardItem] {
        guard !searchText.isEmpty else { return recents }
        return recents.filter {
            $0.content.preview.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredSaved: [ClipboardItem] {
        guard !searchText.isEmpty else { return saved }
        return saved.filter {
            $0.content.preview.localizedCaseInsensitiveContains(searchText) ||
            ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// All items for inline selector: recents first, then saved
    var allItems: [ClipboardItem] {
        let r = searchText.isEmpty ? recents : filteredRecents
        let s = searchText.isEmpty ? saved : filteredSaved
        return r + s
    }

    // MARK: - Actions

    func addRecent(_ item: ClipboardItem) {
        // Skip duplicates (same content as most recent)
        if let first = recents.first, first.content == item.content { return }
        // Remove older duplicate if exists
        recents.removeAll { $0.content == item.content }
        recents.insert(item, at: 0)
        if recents.count > maxRecents {
            recents.removeLast()
        }
    }

    func saveItem(_ item: ClipboardItem, withTitle title: String? = nil) {
        guard !saved.contains(where: { $0.content == item.content }) else { return }
        var newItem = item
        newItem.title = title
        saved.insert(newItem, at: 0)
    }

    func updateTitle(for id: UUID, title: String) {
        if let i = saved.firstIndex(where: { $0.id == id }) {
            saved[i].title = title.isEmpty ? nil : title
        }
    }

    func deleteRecent(_ item: ClipboardItem) {
        recents.removeAll { $0.id == item.id }
    }

    func deleteSaved(_ item: ClipboardItem) {
        saved.removeAll { $0.id == item.id }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        ClipboardMonitor.writeToClipboard(item)
    }
}
