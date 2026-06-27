import SwiftUI

struct MaintenanceBoardView: View {
    @State private var vm = MaintenanceViewModel()
    @State private var selectedTask: MaintenanceTask?
    @State private var showAddTask = false
    @State private var expandedSections: Set<MaintenanceTask.TaskStatus> = Set(MaintenanceTask.TaskStatus.allCases)
    @State private var selectedFilter: MaintenanceFilter = .all

    enum MaintenanceFilter: CaseIterable, Equatable {
        case all, open, inProgress, done

        func label(openCount: Int, inProgressCount: Int, doneCount: Int, totalCount: Int) -> String {
            switch self {
            case .all:        return "All (\(totalCount))"
            case .open:       return "Open (\(openCount))"
            case .inProgress: return "In Progress (\(inProgressCount))"
            case .done:       return "Done (\(doneCount))"
            }
        }
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
                // MARK: Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(MaintenanceFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.label(
                                    openCount: vm.openTasks.count,
                                    inProgressCount: vm.inProgressTasks.count,
                                    doneCount: vm.doneTasks.count,
                                    totalCount: vm.tasks.count
                                ),
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color.bgPrimary)

                Divider()
                    .background(Color.textTertiary.opacity(0.3))

                if vm.isLoading && vm.tasks.isEmpty {
                    ProgressView()
                        .tint(Color.gold)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.bgPrimary.ignoresSafeArea())
                } else if vm.tasks.isEmpty {
                    MaintenanceEmptyStateView()
                } else if selectedFilter == .all {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 16) {
                            MaintenanceSectionView(
                                status: .open,
                                tasks: vm.openTasks,
                                isExpanded: isExpanded(.open),
                                onToggle: { toggleSection(.open) },
                                onTapTask: { selectedTask = $0 }
                            )
                            MaintenanceSectionView(
                                status: .inProgress,
                                tasks: vm.inProgressTasks,
                                isExpanded: isExpanded(.inProgress),
                                onToggle: { toggleSection(.inProgress) },
                                onTapTask: { selectedTask = $0 }
                            )
                            MaintenanceSectionView(
                                status: .done,
                                tasks: vm.doneTasks,
                                isExpanded: isExpanded(.done),
                                onToggle: { toggleSection(.done) },
                                onTapTask: { selectedTask = $0 }
                            )
                        }
                        .padding(16)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                    .background(Color.bgSecondary.ignoresSafeArea())
                } else {
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 12) {
                            if filteredTasks.isEmpty {
                                Text("No tasks")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 40)
                            } else {
                                ForEach(filteredTasks) { task in
                                    TaskCardView(task: task)
                                        .onTapGesture { selectedTask = task }
                                }
                            }
                        }
                        .padding(16)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 80) }
                    .background(Color.bgSecondary.ignoresSafeArea())
                }
            }
            .background(Color.bgPrimary.ignoresSafeArea())
            .navigationTitle("Maintenance")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Text("Maintenance")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textOnNavy)

                        if vm.openTasks.count > 0 {
                            Text("\(vm.openTasks.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.textOnNavy)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Color.negative)
                                .clipShape(Capsule())
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showAddTask = true }) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gold)
                    }
                    .accessibilityLabel("Add task")
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
            .refreshable {
                if let propertyId = AuthService.shared.currentPropertyId {
                    await vm.fetchTasks(propertyId: propertyId)
                }
            }
        }
    }

    private func isExpanded(_ status: MaintenanceTask.TaskStatus) -> Bool {
        expandedSections.contains(status)
    }

    private func toggleSection(_ status: MaintenanceTask.TaskStatus) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(status) {
                expandedSections.remove(status)
            } else {
                expandedSections.insert(status)
            }
        }
    }
}

// MARK: - MaintenanceSectionView

struct MaintenanceSectionView: View {
    let status: MaintenanceTask.TaskStatus
    let tasks: [MaintenanceTask]
    let isExpanded: Bool
    let onToggle: () -> Void
    let onTapTask: (MaintenanceTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    Text(status.displayName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textPrimary)

                    Text("\(tasks.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textOnNavy)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(status.themeColor)
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(isExpanded ? "Collapse" : "Expand") \(status.displayName)")

            if isExpanded {
                VStack(spacing: 12) {
                    if tasks.isEmpty {
                        Text("No tasks")
                            .font(.subheadline)
                            .foregroundStyle(Color.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(tasks) { task in
                            TaskCardView(task: task)
                                .onTapGesture { onTapTask(task) }
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - TaskCardView

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

// MARK: - MaintenanceEmptyStateView

struct MaintenanceEmptyStateView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(Color.textSecondary.opacity(0.55))

            Text("No maintenance tasks")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textSecondary)

            Text("Tap + to add a task")
                .font(.subheadline)
                .foregroundStyle(Color.textSecondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color.bgPrimary.ignoresSafeArea())
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

private extension MaintenanceTask.TaskStatus {
    var themeColor: Color {
        switch self {
        case .open:
            Color.negative
        case .inProgress:
            Color.gold
        case .done:
            Color.positive
        }
    }
}

private extension MaintenanceTask.Priority {
    var themeColor: Color {
        switch self {
        case .low:
            Color.textSecondary
        case .medium:
            Color.gold
        case .high:
            Color.negative
        }
    }
}
