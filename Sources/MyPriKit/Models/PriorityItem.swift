import Foundation

public struct PriorityItem: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var assignees: [String]
    public var notes: String
    public var links: [LinkItem]
    public var priority: PriorityLevel
    public var createdAt: Date
    public var updatedAt: Date

    /// Soft-delete marker. Deleted items stay in the JSON file (as
    /// tombstones) instead of being removed outright, so that when this
    /// file is synced between multiple devices (e.g. via Google Drive), a
    /// device that hasn't seen the deletion yet can't accidentally
    /// resurrect the item by writing its own stale copy back. See
    /// `PriorityStore.merge`.
    public var deletedAt: Date?

    /// User-facing "closed" marker — for priorities that are done/resolved
    /// but worth keeping around for reference, unlike `deletedAt` (which is
    /// an internal sync mechanism, never meant to be user-visible or
    /// reversible from the UI). Closed items are hidden from the normal
    /// priority tiers and shown in a collapsed section instead.
    public var closedAt: Date?

    /// Manual sort position *within this item's priority tier* — lower
    /// sorts first. Only meaningful relative to other items sharing the
    /// same `priority`; changing priority repositions the item within its
    /// new tier. Drives drag-to-reorder in `MainListView`.
    public var order: Double

    public init(
        id: UUID = UUID(),
        title: String = "New Priority",
        assignees: [String] = [],
        notes: String = "",
        links: [LinkItem] = [],
        priority: PriorityLevel = .p2,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        closedAt: Date? = nil,
        order: Double = Date().timeIntervalSinceReferenceDate
    ) {
        self.id = id
        self.title = title
        self.assignees = assignees
        self.notes = notes
        self.links = links
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.closedAt = closedAt
        self.order = order
    }

    public var isDeleted: Bool {
        deletedAt != nil
    }

    public var isClosed: Bool {
        closedAt != nil
    }

    // Custom decoding so files written before `order`/`closedAt` existed
    // (or before a future field is added) still load: missing `order`
    // falls back to the item's creation time, which preserves a sensible
    // relative order. `encode(to:)` is still synthesized automatically.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        assignees = try container.decode([String].self, forKey: .assignees)
        notes = try container.decode(String.self, forKey: .notes)
        links = try container.decode([LinkItem].self, forKey: .links)
        priority = try container.decode(PriorityLevel.self, forKey: .priority)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        deletedAt = try container.decodeIfPresent(Date.self, forKey: .deletedAt)
        closedAt = try container.decodeIfPresent(Date.self, forKey: .closedAt)
        order = try container.decodeIfPresent(Double.self, forKey: .order) ?? createdAt.timeIntervalSinceReferenceDate
    }
}
