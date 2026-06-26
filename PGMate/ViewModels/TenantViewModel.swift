import Foundation
import FirebaseCrashlytics

@Observable
class TenantViewModel {
    var tenants: [Tenant] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var filteredTenants: [Tenant] {
        if searchText.isEmpty {
            return tenants.filter { $0.status == .active }
        }
        return tenants.filter { tenant in
            tenant.status == .active &&
            (tenant.name.localizedCaseInsensitiveContains(searchText) ||
             tenant.roomNumber.localizedCaseInsensitiveContains(searchText) ||
             tenant.phone.contains(searchText))
        }
    }

    func load() async {
        guard let propertyId = auth.currentPropertyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            tenants = try await firestore
                .fetchTenants(propertyId: propertyId)
                .sorted { $0.name < $1.name }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
        }
    }

    func addTenant(_ tenant: Tenant, photoData: Data?) async throws {
        guard let propertyId = auth.currentPropertyId else { return }

        var newTenant = tenant

        // Upload photo if provided
        if let photoData = photoData {
            let url = try await firestore.uploadTenantPhoto(
                photoData: photoData,
                tenantId: tenant.id,
                propertyId: propertyId)
            newTenant.photoURL = url
        }

        try await firestore.saveTenant(newTenant, propertyId: propertyId)

        // Update room status to occupied
        try await firestore.updateRoomStatus(
            id: tenant.roomId, propertyId: propertyId, status: .occupied)

        // Generate rent record for current month
        let now = Date()
        let month = Calendar.current.component(.month, from: now)
        let year = Calendar.current.component(.year, from: now)
        let dueDate = Calendar.current.date(
            from: DateComponents(year: year, month: month, day: 5)) ?? now

        let rentRecord = RentRecord(
            id: UUID().uuidString,
            propertyId: propertyId,
            tenantId: tenant.id,
            tenantName: tenant.name,
            roomNumber: tenant.roomNumber,
            month: month,
            year: year,
            amount: tenant.monthlyRent,
            dueDate: dueDate,
            paidDate: nil,
            paymentMethod: .pending,
            upiTransactionId: nil,
            status: .pending)

        try await firestore.saveRentRecord(rentRecord, propertyId: propertyId)

        await load()
    }

    func checkOut(tenant: Tenant) async throws {
        guard let propertyId = auth.currentPropertyId else { return }

        var updated = tenant
        updated.status = .checkedOut
        updated.checkOutDate = Date()

        try await firestore.saveTenant(updated, propertyId: propertyId)
        try await firestore.updateRoomStatus(
            id: tenant.roomId, propertyId: propertyId, status: .vacant)
        await load()
    }
}
