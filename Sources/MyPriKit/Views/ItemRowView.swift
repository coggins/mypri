import SwiftUI

public struct ItemRowView: View {
    let item: PriorityItem
    var onOpen: () -> Void
    var onDelete: () -> Void
    var onSetPriority: (PriorityLevel) -> Void

    @State private var hovering = false

    public init(
        item: PriorityItem,
        onOpen: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSetPriority: @escaping (PriorityLevel) -> Void
    ) {
        self.item = item
        self.onOpen = onOpen
        self.onDelete = onDelete
        self.onSetPriority = onSetPriority
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
        .onHover { hovering = $0 }
        .contentShape(Rectangle())
        .onTapGesture(perform: onOpen)
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
            Button("Delete", role: .destructive) { onDelete() }
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
