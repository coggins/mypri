import Foundation
import MyPriKit

/// Reads/writes the priorities JSON through a security-scoped URL obtained
/// from the Files picker. This works for any file provider the user has
/// installed — Google Drive, iCloud Drive, Dropbox, etc. — since they all
/// expose files to other apps the same way. NSFileCoordinator ensures our
/// reads/writes are coordinated with the provider's own sync activity.
final class DriveFileIO: PriorityStoreIO {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    func read() -> Data? {
        guard url.startAccessingSecurityScopedResource() else { return nil }
        defer { url.stopAccessingSecurityScopedResource() }

        var result: Data?
        var coordinationError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readURL in
            result = try? Data(contentsOf: readURL)
        }
        if let coordinationError {
            print("DriveFileIO: read coordination failed: \(coordinationError)")
        }
        return result
    }

    func write(_ data: Data) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        var coordinationError: NSError?
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { writeURL in
            do {
                try data.write(to: writeURL, options: .atomic)
            } catch {
                print("DriveFileIO: write failed: \(error)")
            }
        }
        if let coordinationError {
            print("DriveFileIO: write coordination failed: \(coordinationError)")
        }
    }
}
