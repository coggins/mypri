import SwiftUI

public struct MainListView: View {
    @ObservedObject var store: PriorityStore
    var onOpenItem: (UUID) -> Void

    @State private var newTitle: String = ""
    @State private var refreshSpin: Double = 0

    public init(store: PriorityStore, onOpenItem: @escaping (UUID) -> Void) {
        self.store = store
        self.onOpenItem = onOpenItem
    }

    private var visibleItems: [PriorityItem] {
        store.items.filter { !$0.isDeleted }
    }

    private var sortedItems: [PriorityItem] {
        visibleItems.sorted { lhs, rhs in
            if lhs.priority != rhs.priority { return lhs.priority < rhs.priority }
            return lhs.updatedAt > rhs.updatedAt
        }
    }

    public var body: some View {
        ZStack {
            MPPanelBackground()

            VStack(spacing: 0) {
                header
                Divider().overlay(Color.mpBorder)

                if visibleItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(sortedItems) { item in
                                ItemRowView(
                                    item: item,
                                    onOpen: { onOpenItem(item.id) },
                                    onDelete: { store.delete(id: item.id) },
                                    onSetPriority: { level in store.setPriority(id: item.id, to: level) }
                                )
                            }
                        }
                        .padding(10)
                    }
                    .refreshable { store.refresh() }
                }

                Divider().overlay(Color.mpBorder)
                footer
            }
        }
        .frame(minWidth: 220)
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
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundColor(.mpTextTertiary)
            Text("No priorities yet")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mpTextSecondary)
            Button("Add your first priority") { addAndOpen() }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(LinearGradient.mpAccent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            ForEach(PriorityLevel.allCases) { level in
                let count = visibleItems.filter { $0.priority == level }.count
                HStack(spacing: 4) {
                    Circle().fill(level.color).frame(width: 6, height: 6)
                    Text("\(level.label) \(count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.mpTextSecondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
