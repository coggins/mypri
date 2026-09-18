import SwiftUI

public struct TagChipView: View {
    let name: String
    var onRemove: (() -> Void)?

    public init(name: String, onRemove: (() -> Void)? = nil) {
        self.name = name
        self.onRemove = onRemove
    }

    public var body: some View {
        HStack(spacing: 6) {
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.mpTextPrimary)
                .lineLimit(1)
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.mpTextSecondary)
                }
                .buttonStyle(.plain)
            }
        }
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
