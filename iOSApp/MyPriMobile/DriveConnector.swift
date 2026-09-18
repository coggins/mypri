import Foundation
import MyPriKit

/// Owns the connection to the shared priorities file: resolves a persisted
/// security-scoped bookmark at launch, and lets the user (re)connect to a
/// file through the system Files picker.
@MainActor
final class DriveConnector: ObservableObject {
    @Published private(set) var store: PriorityStore?
    @Published private(set) var fileName: String?

    private let bookmarkKey = "MyPri.driveBookmark"

    init() {
        resolveExistingBookmark()
    }

    private func resolveExistingBookmark() {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return }

        attach(url: url)
        if isStale {
            refreshBookmark(for: url)
        }
    }

    private func attach(url: URL) {
        let io = DriveFileIO(url: url)
        store = PriorityStore(io: io)
        fileName = url.lastPathComponent
    }

    private func refreshBookmark(for url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        if let data = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) {
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        }
    }

    /// Connects to a file the user just picked (either an existing file, or
    /// one freshly created via the export flow — either way its content is
    /// already valid JSON by the time we get here).
    func connect(to url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        guard let bookmark = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil) else {
            return
        }
        UserDefaults.standard.set(bookmark, forKey: bookmarkKey)
        attach(url: url)
    }

    func disconnect() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
        store = nil
        fileName = nil
    }
}
