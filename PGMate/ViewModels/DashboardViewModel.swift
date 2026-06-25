import SwiftUI

@Observable
class DashboardViewModel {
    var rooms: [Room] = []
    var tenants: [Tenant] = []
    var rentRecords: [RentRecord] = []
    var maintenanceTasks: [MaintenanceTask] = []
    var isLoading = false
    var errorMessage: String?

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var propertyName: String {
        auth.propertyName
    }

    var ownerName: String {
        auth.ownerName
    }

    // MARK: - Occupancy

    var totalRooms: Int { rooms.count }
    var occupiedRooms: Int {
        rooms.filter { $0.status == .occupied }.count
    }
    var vacantRooms: Int {
        rooms.filter { $0.status == .vacant }.count
    }
    var maintenanceRooms: Int {
        rooms.filter { $0.status == .maintenance }.count
    }
    var occupancyRate: Double {
        guard totalRooms > 0 else { return 0 }
        return Double(occupiedRooms) / Double(totalRooms)
    }

    // MARK: - Financial (current month)

    var currentMonth: Int {
        Calendar.current.component(.month, from: Date())
    }
    var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    var currentMonthRecords: [RentRecord] {
        rentRecords.filter {
            $0.month == currentMonth && $0.year == currentYear
        }
    }
    var totalRentDue: Double {
        currentMonthRecords.reduce(0) { $0 + $1.amount }
    }
    var totalCollected: Double {
        currentMonthRecords
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.amount }
    }
    var totalPending: Double {
        currentMonthRecords
            .filter { $0.status != .paid }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Alerts

    var overdueCount: Int {
        currentMonthRecords.filter { $0.status == .overdue }.count
    }
    var pendingMaintenanceCount: Int {
        maintenanceTasks.filter { $0.status != .done }.count
    }

    // MARK: - Recent Activity (last 5 items)

    var recentActivity: [ActivityItem] {
        var items: [ActivityItem] = []

        // Recent tenant check-ins
        let recentTenants = tenants
            .filter { $0.status == .active }
            .sorted { $0.checkInDate > $1.checkInDate }
            .prefix(2)
        for tenant in recentTenants {
            items.append(ActivityItem(
                icon: "person.fill.badge.plus",
                color: .primaryIndigo,
                title: "\(tenant.name) checked in",
                subtitle: "Room \(tenant.roomNumber)",
                date: tenant.checkInDate
            ))
        }

        // Recent payments
        let recentPayments = currentMonthRecords
            .filter { $0.status == .paid }
            .sorted { ($0.paidDate ?? Date()) > ($1.paidDate ?? Date()) }
            .prefix(2)
        for record in recentPayments {
            items.append(ActivityItem(
                icon: "indianrupeesign.circle.fill",
                color: .successGreen,
                title: "Rent received from \(record.tenantName)",
                subtitle: formatINR(record.amount),
                date: record.paidDate ?? Date()
            ))
        }

        // Recent maintenance
        let recentMaintenance = maintenanceTasks
            .sorted {
                ($0.completedDate ?? $0.scheduledDate ?? Date()) >
                ($1.completedDate ?? $1.scheduledDate ?? Date())
            }
            .prefix(2)
        for task in recentMaintenance {
            items.append(ActivityItem(
                icon: "wrench.fill",
                color: .accentGold,
                title: task.title,
                subtitle: task.status.displayName,
                date: task.completedDate ?? task.scheduledDate ?? Date()
            ))
        }

        return items
            .sorted { $0.date > $1.date }
            .prefix(5)
            .map { $0 }
    }

    // MARK: - Load

    func load() async {
        guard let propertyId = auth.currentPropertyId else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            async let roomsResult = firestore.fetchRooms(propertyId: propertyId)
            async let tenantsResult = firestore.fetchTenants(propertyId: propertyId)
            async let rentResult = firestore.fetchAllRentRecords(propertyId: propertyId)
            async let maintenanceResult = firestore.fetchMaintenanceTasks(propertyId: propertyId)

            let (r, t, rr, m) = try await (
                roomsResult, tenantsResult, rentResult, maintenanceResult)

            await MainActor.run {
                self.rooms = r
                self.tenants = t
                self.rentRecords = rr
                self.maintenanceTasks = m
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - ActivityItem

struct ActivityItem: Identifiable {
    let id = UUID()
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let date: Date

    var timeAgo: String {
        date.timeAgoString
    }
}
