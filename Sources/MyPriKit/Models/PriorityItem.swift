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

    public init(
        id: UUID = UUID(),
        title: String = "New Priority",
        assignees: [String] = [],
        notes: String = "",
        links: [LinkItem] = [],
        priority: PriorityLevel = .p2,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
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
    }

    public var isDeleted: Bool {
        deletedAt != nil
    }
}
