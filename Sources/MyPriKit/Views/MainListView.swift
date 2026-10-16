import SwiftUI

public struct MainListView: View {
    @ObservedObject var store: PriorityStore
    var onOpenItem: (UUID) -> Void

    @State private var newTitle: String = ""
    @State private var searchText: String = ""
    @State private var hiddenPriorities: Set<PriorityLevel> = []
    @State private var isReordering = false
    @State private var refreshSpin: Double = 0
    @State private var isClosedSectionExpanded = false
    @State private var selectedItemID: UUID?

    public init(store: PriorityStore, onOpenItem: @escaping (UUID) -> Void) {
        self.store = store
        self.onOpenItem = onOpenItem
    }

    private var visibleItems: [PriorityItem] {
        store.items.filter { !$0.isDeleted }
    }

    /// Non-deleted, non-closed items — what the normal priority tiers and
    /// footer counts are built from.
    private var activeItems: [PriorityItem] {
        visibleItems.filter { !$0.isClosed }
    }

    private var isFiltering: Bool {
        !hiddenPriorities.isEmpty || !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func matchesSearch(_ item: PriorityItem, query: String) -> Bool {
        guard !query.isEmpty else { return true }
        if item.title.lowercased().contains(query) { return true }
        if item.notes.lowercased().contains(query) { return true }
        if item.assignees.contains(where: { $0.lowercased().contains(query) }) { return true }
        return false
    }

    private var filteredItems: [PriorityItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return activeItems.filter { item in
            guard !hiddenPriorities.contains(item.priority) else { return false }
            return matchesSearch(item, query: query)
        }
    }

    private func group(for level: PriorityLevel) -> [PriorityItem] {
        filteredItems.filter { $0.priority == level }.sorted { $0.order < $1.order }
    }

    private var activeLevels: [PriorityLevel] {
        PriorityLevel.allCases.filter { !group(for: $0).isEmpty }
    }

    /// Closed items, most recently closed first — shown in a collapsed
    /// section so they stay findable without cluttering the active list.
    private var closedItems: [PriorityItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return visibleItems
            .filter { $0.isClosed && matchesSearch($0, query: query) }
            .sorted { ($0.closedAt ?? $0.updatedAt) > ($1.closedAt ?? $1.updatedAt) }
    }

    public var body: some View {
        ZStack {
            MPPanelBackground()

            VStack(spacing: 0) {
                header
                Divider().overlay(Color.mpBorder)

                if activeLevels.isEmpty && closedItems.isEmpty {
                    emptyState
                } else {
                    list
                }

                Divider().overlay(Color.mpBorder)
                footer
            }
        }
        .frame(minWidth: 220)
    }

    private var list: some View {
        List(selection: $selectedItemID) {
            ForEach(activeLevels) { level in
                Section {
                    ForEach(group(for: level)) { item in
                        ItemRowView(
                            item: item,
                            onOpen: { onOpenItem(item.id) },
                            onDelete: { store.delete(id: item.id) },
                            onSetPriority: { newLevel in store.setPriority(id: item.id, to: newLevel) },
                            onToggleClosed: { store.setClosed(id: item.id, closed: !item.isClosed) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .deleteDisabled(true)
                    }
                    .onMove { source, destination in
                        store.moveItems(priority: level, fromOffsets: source, toOffset: destination)
                    }
                    .moveDisabled(!searchText.isEmpty)
                } header: {
                    sectionHeader(level)
                }
            }

            if !closedItems.isEmpty {
                DisclosureGroup(isExpanded: $isClosedSectionExpanded) {
                    ForEach(closedItems) { item in
                        ItemRowView(
                            item: item,
                            onOpen: { onOpenItem(item.id) },
                            onDelete: { store.delete(id: item.id) },
                            onSetPriority: { newLevel in store.setPriority(id: item.id, to: newLevel) },
                            onToggleClosed: { store.setClosed(id: item.id, closed: !item.isClosed) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
                        .deleteDisabled(true)
                        .moveDisabled(true)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 10, weight: .bold))
                        Text("Closed (\(closedItems.count))")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.6)
                        Spacer()
                    }
                    .foregroundColor(.mpTextTertiary)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppear {
                    // This DisclosureGroup is only inserted into the List
                    // once something is actually closed (`if
                    // !closedItems.isEmpty`), and on that first insertion
                    // SwiftUI renders it expanded regardless of the
                    // `isExpanded` binding's value. Explicitly re-asserting
                    // it here corrects that — harmless on a normal app
                    // launch where it's already collapsed.
                    isClosedSectionExpanded = false
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        #if os(iOS)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
        #endif
        .refreshable { store.refresh() }
        .onChange(of: selectedItemID) { newValue in
            // Selection (rather than a tap gesture or a row-wide Button) is
            // what actually opens an item — a Button wrapping the whole row
            // fights with List's native click-and-drag reordering on macOS,
            // since both try to interpret the same mouse-down. Selection is
            // the one interaction List is built to share cleanly with
            // dragging. We reset it right after acting on it so the next
            // click on the same row is a fresh nil → id transition and
            // reliably fires again.
            guard let id = newValue else { return }
            onOpenItem(id)
            selectedItemID = nil
        }
    }

    private func sectionHeader(_ level: PriorityLevel) -> some View {
        HStack(spacing: 6) {
            Circle().fill(level.color).frame(width: 6, height: 6)
            Text("\(level.label) · \(level.description)")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.6)
            Spacer()
        }
        .foregroundColor(.mpTextTertiary)
        .textCase(nil)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient.mpAccent)
                        .frame(width: 22, height: 22)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black.opacity(0.75))
                }
                Text("Priorities")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.mpTextPrimary)
                Spacer()

                #if os(iOS)
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if isReordering {
                            isReordering = false
                        } else {
                            searchText = ""
                            isReordering = true
                        }
                    }
                } label: {
                    Image(systemName: isReordering ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LinearGradient.mpAccent)
                }
                .buttonStyle(.plain)
                .help(isReordering ? "Done reordering" : "Reorder priorities")
                #endif

                Button {
                    store.refresh()
                    withAnimation(.easeInOut(duration: 0.5)) { refreshSpin += 360 }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(LinearGradient.mpAccent)
                        .rotationEffect(.degrees(refreshSpin))
                }
                .buttonStyle(.plain)
                .help("Refresh from file")
            }

            HStack(spacing: 8) {
                TextField("New priority title", text: $newTitle)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.mpSurface))
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mpBorder, lineWidth: 1))
                    .font(.system(size: 12))
                    .foregroundColor(.mpTextPrimary)
                    .onSubmit(addAndOpen)

                Button(action: addAndOpen) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(LinearGradient.mpAccent)
                }
                .buttonStyle(.plain)
                .help("Add Priority")
            }

            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.mpTextTertiary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.mpTextPrimary)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.mpTextTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.mpSurface))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.mpBorder, lineWidth: 1))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func addAndOpen() {
        let id = store.addItem(title: newTitle)
        newTitle = ""
        onOpenItem(id)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: isFiltering ? "line.3.horizontal.decrease.circle" : "tray")
                .font(.system(size: 30))
                .foregroundColor(.mpTextTertiary)
            Text(isFiltering ? "No matching priorities" : "No priorities yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mpTextSecondary)
            if isFiltering {
                Button("Clear filters") {
                    withAnimation {
                        hiddenPriorities.removeAll()
                        searchText = ""
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LinearGradient.mpAccent)
            } else {
                Button("Add your first priority") { addAndOpen() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(LinearGradient.mpAccent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            ForEach(PriorityLevel.allCases) { level in
                let count = activeItems.filter { $0.priority == level }.count
                let isHidden = hiddenPriorities.contains(level)
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        if isHidden {
                            hiddenPriorities.remove(level)
                        } else {
                            hiddenPriorities.insert(level)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle().fill(level.color).frame(width: 6, height: 6)
                        Text("\(level.label) \(count)")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.mpTextSecondary)
                    .opacity(isHidden ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .help(isHidden ? "Show \(level.label)" : "Hide \(level.label)")
            }

            Spacer()

            if !hiddenPriorities.isEmpty {
                Button("Show All") {
                    withAnimation { hiddenPriorities.removeAll() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(LinearGradient.mpAccent)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
