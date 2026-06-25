import Foundation

struct Property: Identifiable, Codable {
    var id: String
    var name: String
    var address: String
    var ownerId: String
    var totalRooms: Int
}
