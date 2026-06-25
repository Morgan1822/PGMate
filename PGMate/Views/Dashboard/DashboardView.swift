import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(greeting), \(vm.ownerName)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.textDark)
                        Text(vm.propertyName)
                            .font(.subheadline)
                            .foregroundColor(.primaryIndigo)
                        Text(Date().formatted(
                            .dateTime.weekday(.wide).day().month(.wide).year()))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // MARK: Occupancy Card
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .stroke(Color.primaryIndigo.opacity(0.15), lineWidth: 14)
                                .frame(width: 140, height: 140)
                            Circle()
                                .trim(from: 0, to: vm.occupancyRate)
                                .stroke(
                                    Color.primaryIndigo,
                                    style: StrokeStyle(lineWidth: 14, lineCap: .round))
                                .frame(width: 140, height: 140)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1), value: vm.occupancyRate)
                            VStack(spacing: 2) {
                                Text("\(vm.occupiedRooms)/\(vm.totalRooms)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.textDark)
                                Text("Rooms")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Text("\(Int(vm.occupancyRate * 100))% Occupied")
                            .font(.headline)
                            .foregroundColor(.textDark)

                        HStack(spacing: 16) {
                            StatusBadge(
                                text: "\(vm.vacantRooms) Vacant",
                                color: .successGreen)
                            StatusBadge(
                                text: "\(vm.maintenanceRooms) Maintenance",
                                color: .accentGold)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
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
                            valueColor: .successGreen)
                        MetricCard(
                            title: "Pending",
                            value: formatINR(vm.totalPending),
                            valueColor: .accentGold)
                    }
                    .padding(.horizontal, 20)

                    // MARK: Alerts
                    if vm.overdueCount > 0 || vm.pendingMaintenanceCount > 0 {
                        VStack(spacing: 10) {
                            if vm.overdueCount > 0 {
                                AlertRow(
                                    icon: "exclamationmark.circle.fill",
                                    message: "\(vm.overdueCount) tenant(s) have overdue rent",
                                    color: .accentGold)
                            }
                            if vm.pendingMaintenanceCount > 0 {
                                AlertRow(
                                    icon: "wrench.fill",
                                    message: "\(vm.pendingMaintenanceCount) maintenance tasks pending",
                                    color: .accentGold)
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // MARK: Quick Actions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(.textDark)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                QuickActionButton(
                                    icon: "person.fill.badge.plus",
                                    label: "Add Tenant",
                                    color: .primaryIndigo)
                                QuickActionButton(
                                    icon: "indianrupeesign.circle.fill",
                                    label: "Record Payment",
                                    color: .successGreen)
                                QuickActionButton(
                                    icon: "wrench.fill",
                                    label: "Add Task",
                                    color: .accentGold)
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // MARK: Recent Activity
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Activity")
                            .font(.headline)
                            .foregroundColor(.textDark)

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
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color.backgroundLight.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if vm.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.05))
                }
            }
            .task {
                await vm.load()
            }
            .onChange(of: AuthService.shared.currentPropertyId) {
                Task { await vm.load() }
            }
            .refreshable {
                await vm.load()
            }
        }
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
                .foregroundColor(color)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.textDark)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - QuickActionButton

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textDark)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
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
                    .foregroundColor(item.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.textDark)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(item.timeAgo)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
