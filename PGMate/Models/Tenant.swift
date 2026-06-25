import Foundation

struct Tenant: Identifiable, Codable {
    var id: String
    var propertyId: String
    var roomId: String
    var roomNumber: String
    var name: String
    var phone: String
    var email: String
    var idProofType: IDProofType
    var checkInDate: Date
    var checkOutDate: Date?
    var depositAmount: Double
    var monthlyRent: Double
    var status: TenantStatus
    var emergencyContactName: String
    var emergencyContactPhone: String
    var photoURL: String?

    enum IDProofType: String, Codable, CaseIterable {
        case aadhaar, passport, drivingLicense, other

        var displayName: String {
            switch self {
            case .aadhaar: return "Aadhaar"
            case .passport: return "Passport"
            case .drivingLicense: return "Driving License"
            case .other: return "Other"
            }
        }
    }

    enum TenantStatus: String, Codable {
        case active, checkedOut
    }

    var initials: String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.last?.prefix(1) ?? ""
        return "\(first)\(last)".uppercased()
    }

    var monthsStayed: Int {
        Calendar.current.dateComponents([.month], from: checkInDate, to: Date()).month ?? 0
    }
}
