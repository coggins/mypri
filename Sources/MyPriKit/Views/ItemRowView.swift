import SwiftUI

public struct ItemRowView: View {
    let item: PriorityItem
    var onOpen: () -> Void
    var onDelete: () -> Void
    var onSetPriority: (PriorityLevel) -> Void
    var onToggleClosed: () -> Void

    @State private var hovering = false
    @State private var showDeleteConfirmation = false

    public init(
        item: PriorityItem,
        onOpen: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSetPriority: @escaping (PriorityLevel) -> Void,
        onToggleClosed: @escaping () -> Void
    ) {
        self.item = item
        self.onOpen = onOpen
        self.onDelete = onDelete
        self.onSetPriority = onSetPriority
        self.onToggleClosed = onToggleClosed
    }

    private var trimmedNotes: String {
        item.notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient.mpAccent)
                .frame(width: 4)
                .padding(.vertical, 8)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    PriorityBadgeView(priority: item.priority)
                    Text(item.title.isEmpty ? "Untitled" : item.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.mpTextPrimary)
                        .lineLimit(2)
                }
                .padding(.trailing, 56)

                if !item.assignees.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(item.assignees, id: \.self) { name in
                            PersonPillView(name: name)
                        }
                    }
                }

                if !trimmedNotes.isEmpty {
                    Text(trimmedNotes)
                        .font(.system(size: 11))
                        .foregroundColor(.mpTextSecondary)
                        .lineLimit(2)
                }

                if !item.links.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10, weight: .semibold))
                        Text(item.links.count == 1 ? "1 link" : "\(item.links.count) links")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.mpElectricBlue)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)

            Spacer(minLength: 0)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(hovering ? Color.mpSurfaceElevated : Color.mpSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mpBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(item.isClosed ? 0.6 : 1)
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .overlay(alignment: .topTrailing) {
            rowActionButtons
                .padding(.top, 10)
                .padding(.trailing, 10)
        }
        .contextMenu {
            Button("Open Details") { onOpen() }
            Menu("Set Priority") {
                ForEach(PriorityLevel.allCases) { level in
                    Button {
                        onSetPriority(level)
                    } label: {
                        if item.priority == level {
                            Label("\(level.label) — \(level.description)", systemImage: "checkmark")
                        } else {
                            Text("\(level.label) — \(level.description)")
                        }
                    }
                }
            }
            Divider()
            Button(item.isClosed ? "Reopen" : "Close") { onToggleClosed() }
            Divider()
            Button("Delete", role: .destructive) { showDeleteConfirmation = true }
        }
        .confirmationDialog(
            "Delete \"\(item.title.isEmpty ? "Untitled" : item.title)\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    /// Small always-visible quick actions in the row's top-right corner —
    /// same actions as the context menu, but discoverable without a
    /// right-click/long-press, and usable identically by touch on iOS.
    private var rowActionButtons: some View {
        HStack(spacing: 14) {
            Button {
                onToggleClosed()
            } label: {
                Image(systemName: item.isClosed ? "arrow.uturn.backward.circle" : "checkmark.circle")
                    .font(.system(size: 13, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(.mpTextTertiary)
            .help(item.isClosed ? "Reopen" : "Close")

            Button {
                showDeleteConfirmation = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(Color.red.opacity(0.75))
            .help("Delete")
        }
    }
}

/// Simple wrapping layout for tag chips.
public struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    public init(spacing: CGFloat = 6) {
        self.spacing = spacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += lineHeight + spacing
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        y += lineHeight
        return CGSize(width: maxWidth.isFinite ? maxWidth : x, height: y)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
