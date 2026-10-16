import XCTest
@testable import MyPriKit

private final class InMemoryIO: PriorityStoreIO {
    var data: Data?
    func read() -> Data? { data }
    func write(_ newData: Data) { data = newData }
}

final class PriorityStoreClosingTests: XCTestCase {
    private func makeStore() -> PriorityStore {
        PriorityStore(io: InMemoryIO())
    }

    func testSetClosedMarksItemClosedWithTimestamp() {
        let store = makeStore()
        let id = store.addItem(title: "Wrap this up")

        store.setClosed(id: id, closed: true)

        let item = store.items.first { $0.id == id }
        XCTAssertEqual(item?.isClosed, true)
        XCTAssertNotNil(item?.closedAt)
    }

    func testSetClosedFalseReopensItem() {
        let store = makeStore()
        let id = store.addItem(title: "Wrap this up")
        store.setClosed(id: id, closed: true)

        store.setClosed(id: id, closed: false)

        let item = store.items.first { $0.id == id }
        XCTAssertEqual(item?.isClosed, false)
        XCTAssertNil(item?.closedAt)
    }

    /// Closing is a distinct, reversible state from deleting — closing an
    /// item must never set `deletedAt`, and the item must still be present
    /// in `items` (just marked closed) rather than tombstoned.
    func testClosingIsNotDeleting() {
        let store = makeStore()
        let id = store.addItem(title: "Still here")

        store.setClosed(id: id, closed: true)

        let item = store.items.first { $0.id == id }
        XCTAssertEqual(item?.isDeleted, false)
        XCTAssertNil(item?.deletedAt)
    }
}
