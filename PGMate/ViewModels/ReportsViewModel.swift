import Foundation
import FirebaseCrashlytics

struct MonthlyReport: Identifiable {
    let id: String          // "2026-05" format
    let month: Date
    let grossCollected: Double      // sum of paid rent records in that month
    let pendingRent: Double         // sum of unpaid rent records in that month
    let maintenanceCost: Double     // sum of estimatedCost for done tasks that month

    var netProfit: Double { grossCollected - maintenanceCost }
}

@Observable
class ReportsViewModel {
    var monthlyData: [MonthlyReport] = []
    var isLoading = false
    var errorMessage: String?
    var selectedMonth: Date = Date()

    var currentMonthReport: MonthlyReport? {
        monthlyData.first {
            Calendar.current.isDate($0.month, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    func fetchReports(propertyId: String) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        do {
            let calendar = Calendar.current
            let now = Date()

            guard let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) else { return }

            // Fetch all records — filter in Swift, no composite indexes needed
            let allRentRecords = try await FirestoreService.shared.fetchAllRentRecords(propertyId: propertyId)
            let allTasks = try await FirestoreService.shared.fetchMaintenanceTasks(propertyId: propertyId)

            // Filter to records within the 6-month window
            let rentRecords = allRentRecords.filter {
                $0.status == .paid &&
                $0.paidDate != nil &&
                $0.paidDate! >= sixMonthsAgo
            }
            let doneTasks = allTasks.filter {
                $0.status == .done &&
                $0.resolvedAt != nil &&
                $0.resolvedAt! >= sixMonthsAgo
            }

            // Group into 6 monthly buckets
            var reports: [MonthlyReport] = []
            for offset in 0..<6 {
                guard let monthDate = calendar.date(byAdding: .month, value: -(5 - offset), to: now) else { continue }
                let monthStart = calendar.startOfMonth(monthDate)
                let monthEnd = calendar.endOfMonth(monthDate)

                // Paid records: use paidDate to attribute to month
                let paidThisMonth = rentRecords.filter { record in
                    guard let paidDate = record.paidDate else { return false }
                    return paidDate >= monthStart && paidDate <= monthEnd
                }
                let grossCollected = paidThisMonth.reduce(0) { $0 + $1.amount }

                // Pending/overdue: use dueDate to attribute to month
                let pendingThisMonth = allRentRecords.filter { record in
                    record.status != .paid &&
                    record.dueDate >= monthStart && record.dueDate <= monthEnd
                }
                let pendingRent = pendingThisMonth.reduce(0) { $0 + $1.amount }

                // Done tasks: use resolvedAt to attribute to month
                let tasksThisMonth = doneTasks.filter { task in
                    guard let resolvedAt = task.resolvedAt else { return false }
                    return resolvedAt >= monthStart && resolvedAt <= monthEnd
                }
                let maintenanceCost = tasksThisMonth.reduce(0) { $0 + $1.estimatedCost }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM"
                let reportId = formatter.string(from: monthDate)

                reports.append(MonthlyReport(
                    id: reportId,
                    month: monthStart,
                    grossCollected: grossCollected,
                    pendingRent: pendingRent,
                    maintenanceCost: maintenanceCost
                ))
            }

            await MainActor.run {
                self.monthlyData = reports
                self.isLoading = false
            }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Calendar helpers

private extension Calendar {
    func startOfMonth(_ date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }

    func endOfMonth(_ date: Date) -> Date {
        guard let start = self.date(from: dateComponents([.year, .month], from: date)),
              let next = self.date(byAdding: .month, value: 1, to: start) else { return date }
        return next.addingTimeInterval(-1)
    }
}
