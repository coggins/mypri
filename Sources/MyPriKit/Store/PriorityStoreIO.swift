import Foundation

/// Abstracts *where* the priorities JSON lives so `PriorityStore` itself
/// stays platform-agnostic. macOS reads/writes a plain file path; iOS reads
////writes through a security-scoped URL obtained from the Files picker
/// (which is how Google Drive, iCloud Drive, etc. expose files to apps).
public protocol PriorityStoreIO: AnyObject {
    func read() -> Data?
    func write(_ data: Data)
}

/// Plain-path file I/O usable on any platform (no sandboxing concerns).
/// This is what the Mac app uses for its Application Support default
/// location and for any custom path chosen via NSSavePanel.
public final class LocalFileIO: PriorityStoreIO {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func read() -> Data? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try? Data(contentsOf: url)
    }

    public func write(_ data: Data) {
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url, options: .atomic)
        } catch {
            print("MyPriKit LocalFileIO: failed to write \(url.path): \(error)")
        }
    }
}
