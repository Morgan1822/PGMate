import SwiftUI

struct MaintenanceTask: Identifiable, Codable {
    var id: String
    var propertyId: String
    var roomNumber: String
    var title: String
    var description: String
    var status: TaskStatus
    var priority: Priority
    var estimatedCost: Double
    var createdAt: Date
    var resolvedAt: Date?

    enum TaskStatus: String, Codable, CaseIterable {
        case open = "open"
        case inProgress = "inProgress"
        case done = "done"

        var displayName: String {
            switch self {
            case .open: return "Open"
            case .inProgress: return "In Progress"
            case .done: return "Done"
            }
        }

        var color: Color {
            switch self {
            case .open: return .red
            case .inProgress: return .accentGold
            case .done: return .successGreen
            }
        }
    }

    enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"

        var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }

        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .accentGold
            case .high: return .red
            }
        }
    }
}
