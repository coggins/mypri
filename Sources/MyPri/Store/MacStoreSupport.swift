import AppKit
import MyPriKit

/// Mac-only helpers for `PriorityStore`: choosing/creating the backing JSON
/// file via NSSavePanel, and revealing it in Finder. Kept out of MyPriKit
/// since NSSavePanel/NSWorkspace aren't available on iOS.
enum MacStoreSupport {
    private static let defaultsKey = "MyPri.dataFilePath"

    static func defaultFileURL() -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = support.appendingPathComponent("MyPri", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("priorities.json")
    }

    static func savedFileURL() -> URL {
        if let path = UserDefaults.standard.string(forKey: defaultsKey) {
            return URL(fileURLWithPath: path)
        }
        let url = defaultFileURL()
        UserDefaults.standard.set(url.path, forKey: defaultsKey)
        return url
    }

    private static func remember(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: defaultsKey)
    }

    /// Presents an NSSavePanel and repoints the store at the chosen file,
    /// creating it if it doesn't already exist.
    static func chooseNewFileLocation(for store: PriorityStore, currentURL: URL) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Choose MyPri Data File"
        panel.nameFieldStringValue = "priorities.json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.directoryURL = currentURL.deletingLastPathComponent()

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        remember(url)
        let alreadyExists = FileManager.default.fileExists(atPath: url.path)
        store.setIO(LocalFileIO(url: url), reload: alreadyExists)
        if !alreadyExists {
            store.saveNow()
        }
        return url
    }

    static func revealInFinder(_ url: URL, store: PriorityStore) {
        store.saveNow()
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
