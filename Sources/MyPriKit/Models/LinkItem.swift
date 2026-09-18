import Foundation

public struct LinkItem: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID = UUID()
    public var title: String
    public var urlString: String

    public init(id: UUID = UUID(), title: String, urlString: String) {
        self.id = id
        self.title = title
        self.urlString = urlString
    }

    public var normalizedURL: URL? {
        var s = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if !s.contains("://") {
            s = "https://" + s
        }
        return URL(string: s)
    }

    public var displayTitle: String {
        title.isEmpty ? urlString : title
    }
}
