import SwiftUI

struct Room: Identifiable, Codable, Hashable {
    var id: String
    var propertyId: String
    var roomNumber: String
    var floor: Int
    var type: RoomType
    var monthlyRent: Double
    var status: RoomStatus
    var amenities: [String]

    enum RoomType: String, Codable, CaseIterable {
        case single, double, triple, dormitory

        var displayName: String {
            switch self {
            case .single: return "Single"
            case .double: return "Double"
            case .triple: return "Triple"
            case .dormitory: return "Dormitory"
            }
        }
    }

    enum RoomStatus: String, Codable, CaseIterable {
        case vacant, occupied, maintenance

        var displayName: String {
            switch self {
            case .vacant: return "Vacant"
            case .occupied: return "Occupied"
            case .maintenance: return "Maintenance"
            }
        }

        var color: Color {
            switch self {
            case .vacant: return .successGreen
            case .occupied: return .primaryIndigo
            case .maintenance: return .accentGold
            }
        }
    }
}
