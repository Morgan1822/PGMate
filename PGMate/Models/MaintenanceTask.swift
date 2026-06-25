import Foundation

struct MaintenanceTask: Identifiable, Codable {
    var id: String
    var propertyId: String
    var roomId: String?
    var roomNumber: String?
    var title: String
    var description: String
    var category: MaintenanceCategory
    var status: TaskStatus
    var assignedTo: String?
    var estimatedCost: Double?
    var actualCost: Double?
    var scheduledDate: Date?
    var completedDate: Date?

    enum MaintenanceCategory: String, Codable, CaseIterable {
        case plumbing, electrical, painting, cleaning, other

        var displayName: String {
            switch self {
            case .plumbing: return "Plumbing"
            case .electrical: return "Electrical"
            case .painting: return "Painting"
            case .cleaning: return "Cleaning"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .plumbing: return "drop.fill"
            case .electrical: return "bolt.fill"
            case .painting: return "paintbrush.fill"
            case .cleaning: return "sparkles"
            case .other: return "wrench.fill"
            }
        }
    }

    enum TaskStatus: String, Codable, CaseIterable {
        case pending, inProgress, done

        var displayName: String {
            switch self {
            case .pending: return "Pending"
            case .inProgress: return "In Progress"
            case .done: return "Done"
            }
        }
    }
}
