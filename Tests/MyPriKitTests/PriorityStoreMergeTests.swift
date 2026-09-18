import XCTest
@testable import MyPriKit

final class PriorityStoreMergeTests: XCTestCase {
    private func item(
        id: UUID = UUID(),
        title: String = "Item",
        updatedAt: Date,
        deletedAt: Date? = nil
    ) -> PriorityItem {
        PriorityItem(id: id, title: title, updatedAt: updatedAt, deletedAt: deletedAt)
    }

    /// A concurrent add on the "remote" side (e.g. another device saved a
    /// brand-new item we haven't loaded yet) must survive the merge even
    /// though our local snapshot never saw it.
    func testConcurrentAddIsNotLost() {
        let now = Date()
        let localOnly = item(title: "Local item", updatedAt: now)
        let remoteOnly = item(title: "Remote item", updatedAt: now)

        let merged = PriorityStore.merge(local: [localOnly], remote: [remoteOnly])

        XCTAssertEqual(merged.count, 2)
        XCTAssertTrue(merged.contains { $0.id == localOnly.id })
        XCTAssertTrue(merged.contains { $0.id == remoteOnly.id })
    }

    /// When the same item was edited on both sides, the newer edit wins —
    /// we never silently keep the older one just because it's "local".
    func testNewerEditWinsRegardlessOfSide() {
        let id = UUID()
        let older = item(id: id, title: "Older title", updatedAt: Date(timeIntervalSince1970: 100))
        let newer = item(id: id, title: "Newer title", updatedAt: Date(timeIntervalSince1970: 200))

        let mergedLocalNewer = PriorityStore.merge(local: [newer], remote: [older])
        XCTAssertEqual(mergedLocalNewer.first?.title, "Newer title")

        let mergedRemoteNewer = PriorityStore.merge(local: [older], remote: [newer])
        XCTAssertEqual(mergedRemoteNewer.first?.title, "Newer title")
    }

    /// A deletion that happened after the other side's last known edit must
    /// stick — a stale device shouldn't be able to resurrect it by writing
    /// its old undeleted copy back.
    func testDeletionAfterEditWins() {
        let id = UUID()
        let staleEdit = item(id: id, title: "Still here?", updatedAt: Date(timeIntervalSince1970: 100))
        let laterDeletion = item(id: id, title: "Still here?", updatedAt: Date(timeIntervalSince1970: 200), deletedAt: Date(timeIntervalSince1970: 200))

        let merged = PriorityStore.merge(local: [staleEdit], remote: [laterDeletion])

        XCTAssertEqual(merged.count, 1)
        XCTAssertTrue(merged.first?.isDeleted ?? false)
    }

    /// An edit made after a deletion (e.g. the user un-deletes by editing
    /// again with a fresh timestamp) should win over the older tombstone.
    func testEditAfterDeletionWins() {
        let id = UUID()
        let earlierDeletion = item(id: id, title: "Gone", updatedAt: Date(timeIntervalSince1970: 100), deletedAt: Date(timeIntervalSince1970: 100))
        let laterRevive = item(id: id, title: "Back", updatedAt: Date(timeIntervalSince1970: 200))

        let merged = PriorityStore.merge(local: [laterRevive], remote: [earlierDeletion])

        XCTAssertEqual(merged.count, 1)
        XCTAssertFalse(merged.first?.isDeleted ?? true)
        XCTAssertEqual(merged.first?.title, "Back")
    }
}
