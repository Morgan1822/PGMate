import SwiftUI

struct RentRecord: Identifiable, Codable {
    var id: String
    var propertyId: String
    var tenantId: String
    var tenantName: String
    var roomNumber: String
    var month: Int
    var year: Int
    var amount: Double
    var dueDate: Date
    var paidDate: Date?
    var paymentMethod: PaymentMethod
    var upiTransactionId: String?
    var status: RentStatus

    enum PaymentMethod: String, Codable, CaseIterable {
        case upi = "UPI"
        case cash = "Cash"
        case bankTransfer = "Bank Transfer"
        case pending = "Pending"
    }

    enum RentStatus: String, Codable {
        case paid, pending, overdue

        var displayName: String {
            switch self {
            case .paid: return "Paid"
            case .pending: return "Pending"
            case .overdue: return "Overdue"
            }
        }

        var color: Color {
            switch self {
            case .paid:    return .positive
            case .pending: return .pending
            case .overdue: return .negative
            }
        }
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        var components = DateComponents()
        components.month = month
        components.year = year
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }
}
