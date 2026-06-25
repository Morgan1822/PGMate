import Foundation

@Observable
class RentViewModel {
    var rentRecords: [RentRecord] = []
    var isLoading = false
    var errorMessage: String?
    var selectedFilter: RentFilter = .all
    var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    var propertyName: String = ""

    enum RentFilter: String, CaseIterable {
        case all = "All"
        case paid = "Paid"
        case pending = "Pending"
        case overdue = "Overdue"
    }

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var filteredRecords: [RentRecord] {
        switch selectedFilter {
        case .all: return rentRecords
        case .paid: return rentRecords.filter { $0.status == .paid }
        case .pending: return rentRecords.filter { $0.status == .pending }
        case .overdue: return rentRecords.filter { $0.status == .overdue }
        }
    }

    var totalCollected: Double {
        rentRecords.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
    }
    var totalPending: Double {
        rentRecords.filter { $0.status != .paid }.reduce(0) { $0 + $1.amount }
    }
    var paidCount: Int { rentRecords.filter { $0.status == .paid }.count }
    var pendingCount: Int { rentRecords.filter { $0.status == .pending }.count }
    var overdueCount: Int { rentRecords.filter { $0.status == .overdue }.count }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        var components = DateComponents()
        components.month = selectedMonth
        components.year = selectedYear
        let date = Calendar.current.date(from: components) ?? Date()
        return formatter.string(from: date)
    }

    func load() async {
        guard let propertyId = auth.currentPropertyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            rentRecords = try await firestore
                .fetchRentRecords(propertyId: propertyId, month: selectedMonth, year: selectedYear)
                .sorted { $0.tenantName < $1.tenantName }
            propertyName = auth.propertyName
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recordPayment(
        record: RentRecord,
        method: RentRecord.PaymentMethod,
        upiTransactionId: String?,
        paidDate: Date
    ) async throws {
        guard let propertyId = auth.currentPropertyId else { return }

        var updated = record
        updated.status = .paid
        updated.paymentMethod = method
        updated.paidDate = paidDate
        updated.upiTransactionId = upiTransactionId

        try await firestore.saveRentRecord(updated, propertyId: propertyId)
        await load()
    }

    func navigateMonth(forward: Bool) {
        if forward {
            if selectedMonth == 12 {
                selectedMonth = 1
                selectedYear += 1
            } else {
                selectedMonth += 1
            }
        } else {
            if selectedMonth == 1 {
                selectedMonth = 12
                selectedYear -= 1
            } else {
                selectedMonth -= 1
            }
        }
        Task { await load() }
    }
}
