import SwiftUI

public enum PriorityLevel: Int, Codable, CaseIterable, Comparable, Identifiable, Sendable {
    case p1 = 1
    case p2 = 2
    case p3 = 3

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .p1: return "P1"
        case .p2: return "P2"
        case .p3: return "P3"
        }
    }

    public var description: String {
        switch self {
        case .p1: return "Critical"
        case .p2: return "Important"
        case .p3: return "Normal"
        }
    }

    public var color: Color {
        switch self {
        case .p1: return .mpElectricBlue
        case .p2: return .mpElectricPurple
        case .p3: return .mpSlate
        }
    }

    public static func < (lhs: PriorityLevel, rhs: PriorityLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
