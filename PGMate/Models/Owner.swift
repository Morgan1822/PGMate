import Foundation

struct Owner: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var propertyId: String
    var createdAt: Date
}
