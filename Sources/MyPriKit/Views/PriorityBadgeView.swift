import SwiftUI

public struct PriorityBadgeView: View {
    let priority: PriorityLevel
    var compact: Bool = false

    public init(priority: PriorityLevel, compact: Bool = false) {
        self.priority = priority
        self.compact = compact
    }

    public var body: some View {
        Text(priority.label)
            .font(.system(size: compact ? 10 : 11, weight: .bold, design: .rounded))
            .foregroundColor(priority.color)
            .padding(.horizontal, compact ? 7 : 9)
            .padding(.vertical, compact ? 2 : 3)
            .background(
                Capsule().fill(priority.color.opacity(0.14))
            )
            .overlay(
                Capsule().stroke(priority.color, lineWidth: 1.4)
            )
    }
}
