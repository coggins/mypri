import XCTest
@testable import MyPriKit

final class PriorityItemDecodingTests: XCTestCase {
    /// The user's existing production data predates the `order` field.
    /// Decoding a file like that must not throw — it should fall back to a
    /// sensible default instead of crashing the app on launch.
    func testDecodingLegacyJSONWithoutOrderFieldSucceeds() throws {
        let json = """
        [
          {
            "id": "66D0258D-D6B3-4BE9-9741-9CA96A25150A",
            "title": "Legacy item",
            "assignees": [],
            "notes": "",
            "links": [],
            "priority": 1,
            "createdAt": "2026-09-18T02:28:30Z",
            "updatedAt": "2026-09-18T02:28:50Z"
          }
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([PriorityItem].self, from: Data(json.utf8))

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].title, "Legacy item")
        XCTAssertFalse(items[0].order.isNaN)
        XCTAssertFalse(items[0].isClosed)
    }

    /// A file with `closedAt` present should decode it and report the item
    /// as closed.
    func testDecodingClosedAtField() throws {
        let json = """
        [
          {
            "id": "66D0258D-D6B3-4BE9-9741-9CA96A25150A",
            "title": "Closed item",
            "assignees": [],
            "notes": "",
            "links": [],
            "priority": 1,
            "createdAt": "2026-09-18T02:28:30Z",
            "updatedAt": "2026-09-18T02:28:50Z",
            "closedAt": "2026-09-20T10:00:00Z"
          }
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([PriorityItem].self, from: Data(json.utf8))

        XCTAssertTrue(items[0].isClosed)
        XCTAssertNotNil(items[0].closedAt)
    }

    /// A file already written by the new code (with `order` present) should
    /// round-trip that exact value rather than falling back to anything.
    func testDecodingModernJSONPreservesOrder() throws {
        let json = """
        [
          {
            "id": "66D0258D-D6B3-4BE9-9741-9CA96A25150A",
            "title": "Modern item",
            "assignees": [],
            "notes": "",
            "links": [],
            "priority": 1,
            "createdAt": "2026-09-18T02:28:30Z",
            "updatedAt": "2026-09-18T02:28:50Z",
            "order": 42.5
          }
        ]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let items = try decoder.decode([PriorityItem].self, from: Data(json.utf8))

        XCTAssertEqual(items[0].order, 42.5)
    }
}
