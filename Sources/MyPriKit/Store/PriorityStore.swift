import Foundation
import Combine
import SwiftUI

/// Cross-platform priority list + JSON persistence. Actual byte I/O is
/// delegated to a `PriorityStoreIO`, so the same store, mutation logic, and
/// SwiftUI views work identically on macOS and iOS.
public final class PriorityStore: ObservableObject {
    @Published public var items: [PriorityItem] = []

    private var io: PriorityStoreIO
    private var saveWorkItem: DispatchWorkItem?

    public init(io: PriorityStoreIO) {
        self.io = io
        load()
    }

    /// Every distinct assignee name used across all (non-deleted) items,
    /// sorted alphabetically — powers the "Assigned To" autocomplete in
    /// `DetailView`.
    public var allAssigneeNames: [String] {
        Array(Set(items.filter { !$0.isDeleted }.flatMap(\.assignees))).sorted()
    }

    /// Points the store at a new backing file, optionally reloading its
    /// contents (pass `reload: false` right after writing a brand-new file
    /// so an empty read doesn't wipe out what was just written).
    public func setIO(_ newIO: PriorityStoreIO, reload: Bool = true) {
        io = newIO
        if reload {
            load()
        }
    }

    public func load() {
        guard let data = io.read(), let decoded = Self.decode(data) else {
            items = []
            return
        }
        items = decoded
    }

    /// Pulls in any changes written by another client (e.g. the other
    /// platform's app, synced through the same Google Drive file) without
    /// discarding local changes that haven't been saved yet — it merges
    /// disk into memory using the same last-write-wins rule as `saveNow()`,
    /// it just doesn't necessarily write anything back. Safe to call
    /// anytime, e.g. when the app returns to the foreground or the user
    /// taps a refresh button.
    public func refresh() {
        guard let data = io.read(), let onDisk = Self.decode(data) else { return }
        items = Self.merge(local: items, remote: onDisk)
    }

    public func scheduleSave() {
        saveWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            self?.saveNow()
        }
        saveWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    /// Merges our in-memory changes with whatever is currently on disk
    /// before writing, so a second device that saved since we last loaded
    /// doesn't get its changes clobbered. This matters because the backing
    /// file is often a Google Drive (or iCloud Drive)-synced file that more
    /// than one device writes to independently and asynchronously — without
    /// this, two devices editing around the same time would just overwrite
    /// each other's whole-file snapshot, silently dropping data.
    public func saveNow() {
        let merged: [PriorityItem]
        if let onDiskData = io.read(), let onDisk = Self.decode(onDiskData) {
            merged = Self.merge(local: items, remote: onDisk)
        } else {
            merged = items
        }
        items = merged

        guard let data = Self.encode(merged) else { return }
        io.write(data)
    }

    /// Per-item last-write-wins merge, keyed by id. An item present on only
    /// one side is kept (so a concurrent add elsewhere is never lost); an
    /// item present on both sides keeps whichever copy has the newer
    /// `updatedAt`. Deletion is just another field change (`deletedAt`
    /// timestamp) under this same rule, so a delete only "wins" over an
    /// edit made after it — never over one made before it — and a stale
    /// device can't resurrect something another device already removed.
    static func merge(local: [PriorityItem], remote: [PriorityItem]) -> [PriorityItem] {
        var byId: [UUID: PriorityItem] = [:]
        for item in remote {
            byId[item.id] = item
        }
        for item in local {
            if let existing = byId[item.id] {
                byId[item.id] = item.updatedAt >= existing.updatedAt ? item : existing
            } else {
                byId[item.id] = item
            }
        }
        return Array(byId.values)
    }

    private static func decode(_ data: Data) -> [PriorityItem]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode([PriorityItem].self, from: data)
        } catch {
            print("MyPriKit: failed to decode data file: \(error)")
            return nil
        }
    }

    private static func encode(_ items: [PriorityItem]) -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            return try encoder.encode(items)
        } catch {
            print("MyPriKit: failed to encode data file: \(error)")
            return nil
        }
    }

    // MARK: - Mutations

    @discardableResult
    public func addItem(title: String = "New Priority") -> UUID {
        var item = PriorityItem()
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        item.title = trimmed.isEmpty ? "New Priority" : trimmed
        item.order = topOrder(for: item.priority)
        items.insert(item, at: 0)
        scheduleSave()
        return item.id
    }

    /// The order value that places an item above everything currently in
    /// the given priority tier.
    private func topOrder(for priority: PriorityLevel, excluding excludedId: UUID? = nil) -> Double {
        let minExisting = items
            .filter { $0.priority == priority && !$0.isDeleted && $0.id != excludedId }
            .map(\.order)
            .min()
        return (minExisting ?? 0) - 1
    }

    /// Soft-delete: marks the item as deleted (tombstone) rather than
    /// removing it from the array outright, so the deletion itself can
    /// propagate to other devices through the normal merge instead of
    /// getting lost or undone by a concurrent stale write. Deleted items
    /// are filtered out of the UI (see `PriorityItem.isDeleted`).
    public func delete(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].deletedAt = Date()
        items[idx].updatedAt = Date()
        scheduleSave()
    }

    public func setPriority(id: UUID, to priority: PriorityLevel) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        if items[idx].priority != priority {
            items[idx].order = topOrder(for: priority, excluding: id)
        }
        items[idx].priority = priority
        items[idx].updatedAt = Date()
        scheduleSave()
    }

    /// Closes or reopens an item. Unlike `delete`, this is a fully
    /// user-visible, reversible state — closed items stay findable in the
    /// UI's collapsed "Closed" section rather than disappearing.
    public func setClosed(id: UUID, closed: Bool) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].closedAt = closed ? Date() : nil
        items[idx].updatedAt = Date()
        scheduleSave()
    }

    public func index(of id: UUID) -> Int? {
        items.firstIndex { $0.id == id }
    }

    /// A live, two-way binding into the store's array, so edits made in a
    /// detail view autosave immediately without a separate copy/merge step.
    public func binding(for id: UUID) -> Binding<PriorityItem> {
        Binding<PriorityItem>(
            get: { [weak self] in
                self?.items.first { $0.id == id } ?? PriorityItem(id: id)
            },
            set: { [weak self] newValue in
                guard let self, let idx = self.index(of: id) else { return }
                var updated = newValue
                if updated.priority != self.items[idx].priority {
                    updated.order = self.topOrder(for: updated.priority, excluding: id)
                }
                updated.updatedAt = Date()
                self.items[idx] = updated
                self.scheduleSave()
            }
        )
    }

    /// Reorders items within a single priority tier (drag-to-reorder).
    /// `source`/`destination` follow `Array.move(fromOffsets:toOffset:)`
    /// semantics over that tier's own items sorted by `order` — the same
    /// array a `List` section for this tier would be displaying, so this is
    /// meant to be called directly from a `.onMove` handler.
    public func moveItems(priority: PriorityLevel, fromOffsets source: IndexSet, toOffset destination: Int) {
        var group = items
            .filter { $0.priority == priority && !$0.isDeleted }
            .sorted { $0.order < $1.order }
        group.move(fromOffsets: source, toOffset: destination)

        var didChange = false
        for (position, groupItem) in group.enumerated() {
            let newOrder = Double(position)
            guard groupItem.order != newOrder, let idx = index(of: groupItem.id) else { continue }
            items[idx].order = newOrder
            items[idx].updatedAt = Date()
            didChange = true
        }
        if didChange {
            scheduleSave()
        }
    }
}
