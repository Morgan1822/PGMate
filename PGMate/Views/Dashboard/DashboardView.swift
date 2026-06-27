import SwiftUI

struct DashboardView: View {
    @State private var vm = DashboardViewModel()
    @State private var navigateToOverdueRent = false
    @State private var navigateToOpenMaintenance = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<21: return "Good evening"
        default:      return "Good night"
        }
    }

    var greetingIcon: (name: String, color: Color) {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return ("sun.max.fill", Color.gold)
        case 12..<17: return ("sun.haze.fill", Color.orange)
        case 17..<21: return ("sunset.fill", Color.orange)
        default:      return ("moon.stars.fill", Color(red: 0.75, green: 0.9, blue: 1.0))
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
                                HStack(spacing: 8) {
                                    Text("\(greeting), \(vm.ownerName)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.textPrimary)
                                    Image(systemName: greetingIcon.name)
                                        .font(.title2)
                                        .foregroundStyle(greetingIcon.color)
                                }
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
                                    Circle()
                                        .stroke(Color.surfaceElevated, lineWidth: 14)
                                        .frame(width: 140, height: 140)
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
                                        Button {
                                            navigateToOverdueRent = true
                                        } label: {
                                            AlertRow(
                                                icon: "exclamationmark.circle.fill",
                                                message: "\(vm.overdueCount) tenant(s) have overdue rent",
                                                color: .negative)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    if vm.pendingMaintenanceCount > 0 {
                                        Button {
                                            navigateToOpenMaintenance = true
                                        } label: {
                                            AlertRow(
                                                icon: "wrench.fill",
                                                message: "\(vm.pendingMaintenanceCount) maintenance tasks pending",
                                                color: .warning)
                                        }
                                        .buttonStyle(.plain)
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
            .navigationDestination(isPresented: $navigateToOverdueRent) {
                OverdueRentView()
            }
            .navigationDestination(isPresented: $navigateToOpenMaintenance) {
                OpenMaintenanceView()
            }
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

// MARK: - OverdueRentView

struct OverdueRentView: View {
    @State private var vm = RentViewModel()
    @State private var selectedRecord: RentRecord?

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView()
                    .tint(Color.gold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgSecondary)
            } else if vm.filteredRecords.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Overdue Rent",
                    subtitle: "All tenants are up to date")
            } else {
                List {
                    ForEach(vm.filteredRecords) { record in
                        RentRecordRow(record: record)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if record.status != .paid { selectedRecord = record }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .background(Color.bgSecondary.ignoresSafeArea())
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
            }
        }
        .background(Color.bgSecondary.ignoresSafeArea())
        .navigationTitle("Overdue Rent")
        .navigationBarTitleDisplayMode(.inline)
        .navyNavBar()
        .onAppear { vm.selectedFilter = .overdue }
        .task { await vm.load() }
        .onChange(of: AuthService.shared.currentPropertyId) {
            Task { await vm.load() }
        }
        .sheet(item: $selectedRecord) { record in
            RecordPaymentView(record: record, viewModel: vm)
        }
    }
}

// MARK: - OpenMaintenanceView

struct OpenMaintenanceView: View {
    @State private var vm = MaintenanceViewModel()
    @State private var selectedTask: MaintenanceTask?

    var body: some View {
        Group {
            if vm.isLoading && vm.tasks.isEmpty {
                ProgressView()
                    .tint(Color.gold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgSecondary)
            } else if vm.openTasks.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Open Tasks",
                    subtitle: "All maintenance tasks are resolved")
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(vm.openTasks) { task in
                            TaskCardView(task: task)
                                .onTapGesture { selectedTask = task }
                        }
                    }
                    .padding(16)
                }
                .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                .background(Color.bgSecondary.ignoresSafeArea())
            }
        }
        .background(Color.bgSecondary.ignoresSafeArea())
        .navigationTitle("Open Tasks")
        .navigationBarTitleDisplayMode(.inline)
        .navyNavBar()
        .task {
            if let propertyId = AuthService.shared.currentPropertyId {
                await vm.fetchTasks(propertyId: propertyId)
            }
        }
        .onChange(of: AuthService.shared.currentPropertyId) {
            if let propertyId = AuthService.shared.currentPropertyId {
                Task { await vm.fetchTasks(propertyId: propertyId) }
            }
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailSheet(task: task, viewModel: vm)
        }
    }
}
