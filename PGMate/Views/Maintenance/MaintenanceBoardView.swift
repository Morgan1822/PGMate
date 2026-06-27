import SwiftUI

struct MaintenanceBoardView: View {
    @State private var vm = MaintenanceViewModel()
    @State private var selectedTask: MaintenanceTask?
    @State private var showAddTask = false
    @State private var selectedFilter: MaintenanceFilter = .all

    enum MaintenanceFilter: CaseIterable, Equatable {
        case all, open, inProgress, done
    }

    private var filteredTasks: [MaintenanceTask] {
        switch selectedFilter {
        case .all:        return vm.tasks
        case .open:       return vm.openTasks
        case .inProgress: return vm.inProgressTasks
        case .done:       return vm.doneTasks
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // MARK: Summary row
                HStack(spacing: 12) {
                    SmallMetricCard(
                        label: "Open Tasks",
                        value: "\(vm.openTasks.count)",
                        color: .negative)
                    SmallMetricCard(
                        label: "In Progress",
                        value: "\(vm.inProgressTasks.count)",
                        color: .pending)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.bgPrimary)

                Divider()
                    .background(Color.textTertiary.opacity(0.3))

                // MARK: Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MaintenanceFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filterLabel(filter),
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .background(Color.bgPrimary)

                // MARK: Task list
                if vm.isLoading && vm.tasks.isEmpty {
                    VStack(spacing: 10) {
                        ProgressView().tint(Color.gold)
                        Text("Loading...").foregroundStyle(Color.textSecondary).font(.caption)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)
                } else if filteredTasks.isEmpty {
                    EmptyStateView(
                        icon: "wrench.and.screwdriver",
                        title: selectedFilter == .all ? "No Tasks Yet" : "No \(filterTitle(selectedFilter)) Tasks",
                        subtitle: selectedFilter == .all
                            ? "Tap + to log a maintenance task"
                            : "No tasks with this status")
                } else {
                    List {
                        ForEach(filteredTasks) { task in
                            MaintenanceTaskRow(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedTask = task }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.bgSecondary.ignoresSafeArea())
                    .scrollContentBackground(.hidden)
                    .contentMargins(.bottom, 80, for: .scrollContent)
                    .refreshable {
                        if let propertyId = AuthService.shared.currentPropertyId {
                            await vm.fetchTasks(propertyId: propertyId)
                        }
                    }
                }
            }
            .background(Color.bgPrimary)
            .navigationTitle("Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gold)
                    }
                }
            }
            .sheet(item: $selectedTask) { task in
                TaskDetailSheet(task: task, viewModel: vm)
            }
            .sheet(isPresented: $showAddTask) {
                AddMaintenanceView(viewModel: vm)
            }
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
        }
    }

    private func filterLabel(_ filter: MaintenanceFilter) -> String {
        switch filter {
        case .all:        return "All (\(vm.tasks.count))"
        case .open:       return "Open (\(vm.openTasks.count))"
        case .inProgress: return "In Progress (\(vm.inProgressTasks.count))"
        case .done:       return "Done (\(vm.doneTasks.count))"
        }
    }

    private func filterTitle(_ filter: MaintenanceFilter) -> String {
        switch filter {
        case .all:        return "All"
        case .open:       return "Open"
        case .inProgress: return "In Progress"
        case .done:       return "Done"
        }
    }
}

// MARK: - MaintenanceTaskRow

struct MaintenanceTaskRow: View {
    let task: MaintenanceTask

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(2)
                Text(task.roomNumber.isEmpty ? "No room assigned" : "Room \(task.roomNumber)")
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
                HStack(spacing: 5) {
                    Circle()
                        .fill(task.priority.themeColor)
                        .frame(width: 7, height: 7)
                    Text(task.priority.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(task.priority.themeColor)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if task.estimatedCost > 0 {
                    Text(formatINR(task.estimatedCost))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                }
                StatusBadge(text: task.status.displayName, color: task.status.themeColor)
            }

            if task.status != .done {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .padding(14)
        .background(Color.surface, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

// MARK: - TaskCardView
// Used by OpenMaintenanceView in DashboardView

struct TaskCardView: View {
    let task: MaintenanceTask

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !task.roomNumber.isEmpty {
                        Text("Room \(task.roomNumber)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textOnNavy)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.navyLight)
                            .clipShape(Capsule())
                    }
                }

                StatusBadge(text: task.status.displayName, color: task.status.themeColor)
                    .fixedSize(horizontal: true, vertical: false)
            }

            HStack(spacing: 14) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(task.priority.themeColor)
                        .frame(width: 8, height: 8)
                    Text(task.priority.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(task.priority.themeColor)
                }

                if task.estimatedCost > 0 {
                    Text(formatINR(task.estimatedCost))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                }

                Spacer(minLength: 8)

                Text(task.createdAt.timeAgoString)
                    .font(.caption)
                    .foregroundStyle(Color.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: Color.black.opacity(0.07), radius: 8, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - TaskDetailSheet

struct TaskDetailSheet: View {
    let task: MaintenanceTask
    let viewModel: MaintenanceViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false

    var otherStatuses: [MaintenanceTask.TaskStatus] {
        MaintenanceTask.TaskStatus.allCases.filter { $0 != task.status }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Task Details") {
                    DetailRow(label: "Title", value: task.title)
                    if !task.roomNumber.isEmpty {
                        DetailRow(label: "Room", value: task.roomNumber)
                    }
                    DetailRow(label: "Priority", value: task.priority.displayName, valueColor: task.priority.themeColor)
                    DetailRow(label: "Status", value: task.status.displayName, valueColor: task.status.themeColor)
                    if task.estimatedCost > 0 {
                        DetailRow(label: "Estimated Cost", value: formatINR(task.estimatedCost))
                    }
                    DetailRow(
                        label: "Created",
                        value: task.createdAt.formatted(.dateTime.day().month(.wide).year())
                    )
                    if let resolvedAt = task.resolvedAt {
                        DetailRow(
                            label: "Resolved",
                            value: resolvedAt.formatted(.dateTime.day().month(.wide).year())
                        )
                    }
                }
                .listRowBackground(Color.surface)

                if !task.description.isEmpty {
                    Section("Description") {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundStyle(Color.textPrimary)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.surface)
                }

                Section("Move to") {
                    ForEach(otherStatuses, id: \.self) { status in
                        Button(action: {
                            guard let propertyId = AuthService.shared.currentPropertyId else { return }
                            Task {
                                await viewModel.moveTask(task, to: status, propertyId: propertyId)
                                dismiss()
                            }
                        }) {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(status.themeColor)
                                    .frame(width: 10, height: 10)
                                Text(status.displayName)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.gold)
                            }
                        }
                    }
                }
                .listRowBackground(Color.surface)

                Section {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Label("Delete Task", systemImage: "trash")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Color.bgSecondary.ignoresSafeArea())
            .tint(Color.gold)
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.gold)
                }
            }
            .alert("Delete Task?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    guard let propertyId = AuthService.shared.currentPropertyId else { return }
                    Task {
                        await viewModel.deleteTask(task, propertyId: propertyId)
                        dismiss()
                    }
                }
            } message: {
                Text("This will permanently delete \"\(task.title)\". This action cannot be undone.")
            }
        }
    }
}

// MARK: - DetailRow

struct DetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .textPrimary

    var body: some View {
        LabeledContent {
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(valueColor)
        } label: {
            Text(label)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: - Status theme colors

private extension MaintenanceTask.TaskStatus {
    var themeColor: Color {
        switch self {
        case .open:       Color.negative
        case .inProgress: Color.pending
        case .done:       Color.positive
        }
    }
}

private extension MaintenanceTask.Priority {
    var themeColor: Color {
        switch self {
        case .low:    Color.textSecondary
        case .medium: Color.gold
        case .high:   Color.negative
        }
    }
}
