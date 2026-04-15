import Foundation
import AppKit

// MARK: - Clip Content

enum ClipContent: Equatable {
    case text(String)
    case image(Data)

    var preview: String {
        switch self {
        case .text(let s):
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(trimmed.prefix(200))
        case .image:
            return "[Imagen]"
        }
    }

    var fullText: String? {
        if case .text(let s) = self { return s }
        return nil
    }
}

// MARK: - Codable

extension ClipContent: Codable {
    private enum CodingKeys: String, CodingKey {
        case type, textValue, imageData
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let s):
            try container.encode("text", forKey: .type)
            try container.encode(s, forKey: .textValue)
        case .image(let d):
            try container.encode("image", forKey: .type)
            try container.encode(d, forKey: .imageData)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            let s = try container.decode(String.self, forKey: .textValue)
            self = .text(s)
        case "image":
            let d = try container.decode(Data.self, forKey: .imageData)
            self = .image(d)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .type, in: container,
                debugDescription: "Unknown clip type: \(type)"
            )
        }
    }
}

// MARK: - Clipboard Item

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: ClipContent
    let timestamp: Date
    var title: String?

    init(content: ClipContent, title: String? = nil) {
        self.id = UUID()
        self.content = content
        self.timestamp = Date()
        self.title = title
    }

    /// "13 abr 23:45" for saved, or relative for recents
    var savedDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_AR")
        f.dateFormat = "d MMM HH:mm"
        return f.string(from: timestamp)
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 5 { return "ahora" }
        if interval < 60 { return "hace \(Int(interval))s" }
        if interval < 3600 { return "hace \(Int(interval / 60)) min" }
        if interval < 86400 { return "hace \(Int(interval / 3600))h" }
        return savedDateString
    }
}
