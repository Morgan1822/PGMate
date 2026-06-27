import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.bgPrimary.ignoresSafeArea()
                if vm.isLoading {
                    loadingView
                } else {
                    ScrollView {
                        VStack(spacing: 20) {

                            // MARK: Header
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(greeting), \(vm.ownerName)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.textPrimary)
                                Text(vm.propertyName)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.gold)
                                Text(Date().formatted(
                                    .dateTime.weekday(.wide).day().month(.wide).year()))
                                    .font(.caption)
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                            // MARK: Occupancy Card
                            VStack(spacing: 16) {
                                ZStack {
                                    // Track ring
                                    Circle()
                                        .stroke(Color.surfaceElevated, lineWidth: 14)
                                        .frame(width: 140, height: 140)
                                    // Gold progress ring
                                    Circle()
                                        .trim(from: 0, to: vm.occupancyRate)
                                        .stroke(
                                            Color.gold,
                                            style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                        .frame(width: 140, height: 140)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.easeInOut(duration: 1), value: vm.occupancyRate)
                                    VStack(spacing: 2) {
                                        Text("\(vm.occupiedRooms)/\(vm.totalRooms)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(Color.textPrimary)
                                        Text("Rooms")
                                            .font(.caption)
                                            .foregroundStyle(Color.textSecondary)
                                    }
                                }

                                Text("\(Int(vm.occupancyRate * 100))% Occupied")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)

                                HStack(spacing: 16) {
                                    StatusBadge(
                                        text: "\(vm.vacantRooms) Vacant",
                                        color: .positive)
                                    StatusBadge(
                                        text: "\(vm.maintenanceRooms) Maintenance",
                                        color: .warning)
                                }
                            }
                            .padding(24)
                            .frame(maxWidth: .infinity)
                            .background(Color.surface, in: RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)

                            // MARK: Financial Summary
                            HStack(spacing: 12) {
                                MetricCard(
                                    title: "Total Due",
                                    value: formatINR(vm.totalRentDue))
                                MetricCard(
                                    title: "Collected",
                                    value: formatINR(vm.totalCollected),
                                    valueColor: .positive)
                                MetricCard(
                                    title: "Pending",
                                    value: formatINR(vm.totalPending),
                                    valueColor: .pending)
                            }
                            .padding(.horizontal, 20)

                            // MARK: Alerts
                            if vm.overdueCount > 0 || vm.pendingMaintenanceCount > 0 {
                                VStack(spacing: 10) {
                                    if vm.overdueCount > 0 {
                                        AlertRow(
                                            icon: "exclamationmark.circle.fill",
                                            message: "\(vm.overdueCount) tenant(s) have overdue rent",
                                            color: .negative)
                                    }
                                    if vm.pendingMaintenanceCount > 0 {
                                        AlertRow(
                                            icon: "wrench.fill",
                                            message: "\(vm.pendingMaintenanceCount) maintenance tasks pending",
                                            color: .warning)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }

                            // MARK: Recent Activity
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Activity")
                                    .font(.headline)
                                    .foregroundStyle(Color.textPrimary)

                                if vm.recentActivity.isEmpty {
                                    EmptyStateView(
                                        icon: "clock.fill",
                                        title: "No Recent Activity",
                                        subtitle: "Activity will appear here as you manage your PG")
                                } else {
                                    VStack(spacing: 0) {
                                        ForEach(vm.recentActivity) { item in
                                            ActivityRow(item: item)
                                            if item.id != vm.recentActivity.last?.id {
                                                Divider()
                                                    .padding(.leading, 52)
                                            }
                                        }
                                    }
                                    .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
                                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal, 20)

                            Spacer(minLength: 20)
                        }
                        .padding(.bottom, 20)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)
                    .refreshable { await vm.load() }
                    .ignoresSafeArea(.container, edges: .bottom)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .task { await vm.load() }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task { await vm.load() }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 10) {
            ProgressView()
                .tint(Color.gold)
            Text("Loading...")
                .foregroundStyle(Color.textSecondary)
                .font(.caption)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.bgPrimary.ignoresSafeArea())
    }
}

// MARK: - AlertRow

struct AlertRow: View {
    let icon: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - ActivityRow

struct ActivityRow: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(item.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
            Text(item.timeAgo)
                .font(.caption2)
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
