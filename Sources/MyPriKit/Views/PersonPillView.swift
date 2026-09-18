import SwiftUI

/// Outlined pill used to display an assignee's name on a priority row.
public struct PersonPillView: View {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        Text(name)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.mpTextPrimary)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color.mpElectricBlue.opacity(0.16), Color.mpElectricPurple.opacity(0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .overlay(
                Capsule().strokeBorder(LinearGradient.mpAccent, lineWidth: 1.4)
            )
    }
}
