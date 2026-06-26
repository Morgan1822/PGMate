import SwiftUI

struct MaintenanceBoardView: View {
    @State private var vm = MaintenanceViewModel()
    @State private var selectedTask: MaintenanceTask?
    @State private var showAddTask = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.tasks.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.tasks.isEmpty {
                    EmptyStateView(
                        icon: "wrench.and.screwdriver",
                        title: "No Maintenance Tasks",
                        subtitle: "Tap + to add your first task")
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 16) {
                            KanbanColumnView(
                                status: .open,
                                tasks: vm.openTasks,
                                onTap: { selectedTask = $0 })
                            KanbanColumnView(
                                status: .inProgress,
                                tasks: vm.inProgressTasks,
                                onTap: { selectedTask = $0 })
                            KanbanColumnView(
                                status: .done,
                                tasks: vm.doneTasks,
                                onTap: { selectedTask = $0 })
                        }
                        .padding(16)
                    }
                }
            }
            .background(Color.backgroundLight.ignoresSafeArea())
            .navigationTitle("Maintenance")
            .navigationBarTitleDisplayMode(.large)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if vm.openTasks.count > 0 {
                            Text("\(vm.openTasks.count) open")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red)
                                .clipShape(Capsule())
                        }
                        Button(action: { showAddTask = true }) {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
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
            .refreshable {
                if let propertyId = AuthService.shared.currentPropertyId {
                    await vm.fetchTasks(propertyId: propertyId)
                }
            }
        }
    }
}

// MARK: - KanbanColumnView

struct KanbanColumnView: View {
    let status: MaintenanceTask.TaskStatus
    let tasks: [MaintenanceTask]
    let onTap: (MaintenanceTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Column header
            HStack {
                Text(status.displayName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.textDark)
                Spacer()
                Text("\(tasks.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(tasks.isEmpty ? .secondary : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(tasks.isEmpty ? Color.gray.opacity(0.2) : status.color)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // Task cards
            VStack(spacing: 10) {
                if tasks.isEmpty {
                    Text("No tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                } else {
                    ForEach(tasks) { task in
                        TaskCardView(task: task)
                            .onTapGesture { onTap(task) }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 12)
        }
        .frame(width: 260)
        .background(status.color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(status.color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - TaskCardView

struct TaskCardView: View {
    let task: MaintenanceTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(task.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.textDark)
                .lineLimit(2)

            // Room chip
            if !task.roomNumber.isEmpty {
                Text("Room \(task.roomNumber)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryIndigo)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryIndigo.opacity(0.1))
                    .clipShape(Capsule())
            }

            HStack {
                // Priority
                HStack(spacing: 4) {
                    Circle()
                        .fill(task.priority.color)
                        .frame(width: 6, height: 6)
                    Text(task.priority.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Cost
                if task.estimatedCost > 0 {
                    Text(formatINR(task.estimatedCost))
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.textDark)
                }
            }

            // Time ago
            Text(task.createdAt.timeAgoString)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                // Details
                Section("Task Details") {
                    LabeledContent("Title", value: task.title)
                    if !task.roomNumber.isEmpty {
                        LabeledContent("Room", value: task.roomNumber)
                    }
                    LabeledContent("Priority", value: task.priority.displayName)
                    if task.estimatedCost > 0 {
                        LabeledContent("Estimated Cost", value: formatINR(task.estimatedCost))
                    }
                    LabeledContent("Created", value: task.createdAt.formatted(
                        .dateTime.day().month(.wide).year()))
                    if let resolvedAt = task.resolvedAt {
                        LabeledContent("Resolved", value: resolvedAt.formatted(
                            .dateTime.day().month(.wide).year()))
                    }
                }

                if !task.description.isEmpty {
                    Section("Description") {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.textDark)
                    }
                }

                // Move to
                Section("Move to") {
                    ForEach(otherStatuses, id: \.self) { status in
                        Button(action: {
                            guard let propertyId = AuthService.shared.currentPropertyId else { return }
                            Task {
                                await viewModel.moveTask(task, to: status, propertyId: propertyId)
                                dismiss()
                            }
                        }) {
                            HStack {
                                Circle()
                                    .fill(status.color)
                                    .frame(width: 10, height: 10)
                                Text(status.displayName)
                                    .foregroundColor(.textDark)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Delete
                Section {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        HStack {
                            Spacer()
                            Label("Delete Task", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
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
