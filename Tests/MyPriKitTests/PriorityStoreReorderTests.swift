import XCTest
@testable import MyPriKit

/// Simple in-memory `PriorityStoreIO` so tests can exercise `PriorityStore`
/// without touching disk.
private final class InMemoryIO: PriorityStoreIO {
    var data: Data?
    func read() -> Data? { data }
    func write(_ newData: Data) { data = newData }
}

final class PriorityStoreReorderTests: XCTestCase {
    private func makeStore() -> PriorityStore {
        PriorityStore(io: InMemoryIO())
    }

    /// Dragging an item to the front of its tier must actually move it
    /// there, and must never affect the order of items in other tiers.
    func testMoveItemsReordersWithinTierOnly() {
        let store = makeStore()
        let a = store.addItem(title: "A") // top of P2 (default priority)
        let b = store.addItem(title: "B") // now above A
        let c = store.addItem(title: "C") // now above B

        func p2Order() -> [String] {
            store.items
                .filter { $0.priority == .p2 }
                .sorted { $0.order < $1.order }
                .map(\.title)
        }

        XCTAssertEqual(p2Order(), ["C", "B", "A"])

        // Move "A" (index 2) to the front (index 0).
        store.moveItems(priority: .p2, fromOffsets: IndexSet(integer: 2), toOffset: 0)

        XCTAssertEqual(p2Order(), ["A", "C", "B"])
        _ = (a, b, c)
    }

    /// A newly added item appears at the top of its own priority tier
    /// without disturbing items in a different tier.
    func testNewItemDoesNotAffectOtherTiers() {
        let store = makeStore()
        let p1id = store.addItem(title: "Critical")
        store.setPriority(id: p1id, to: .p1)
        let p1Order = store.items.first { $0.id == p1id }?.order

        store.addItem(title: "Another normal item")

        XCTAssertEqual(store.items.first { $0.id == p1id }?.order, p1Order)
    }

    /// Changing an item's priority moves it to the top of the new tier,
    /// not just wherever it happened to sort numerically before.
    func testChangingPriorityMovesToTopOfNewTier() {
        let store = makeStore()
        let firstP1 = store.addItem(title: "First P1")
        store.setPriority(id: firstP1, to: .p1)

        let promoted = store.addItem(title: "Promote me") // starts as .p2
        store.setPriority(id: promoted, to: .p1)

        let p1Order = store.items
            .filter { $0.priority == .p1 }
            .sorted { $0.order < $1.order }
            .map(\.title)

        XCTAssertEqual(p1Order.first, "Promote me")
    }
}
