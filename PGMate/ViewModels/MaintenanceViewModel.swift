import Foundation

@Observable
class MaintenanceViewModel {
    var tasks: [MaintenanceTask] = []
    var isLoading = false
    var errorMessage: String?
    var showAddTask = false

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var openTasks: [MaintenanceTask] {
        tasks.filter { $0.status == .open }
            .sorted { $0.createdAt > $1.createdAt }
    }
    var inProgressTasks: [MaintenanceTask] {
        tasks.filter { $0.status == .inProgress }
            .sorted { $0.createdAt > $1.createdAt }
    }
    var doneTasks: [MaintenanceTask] {
        tasks.filter { $0.status == .done }
            .sorted { ($0.resolvedAt ?? $0.createdAt) > ($1.resolvedAt ?? $1.createdAt) }
    }

    func fetchTasks(propertyId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            tasks = try await firestore.fetchMaintenanceTasks(propertyId: propertyId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func moveTask(_ task: MaintenanceTask, to status: MaintenanceTask.TaskStatus, propertyId: String) async {
        let resolvedAt: Date? = status == .done ? Date() : nil
        do {
            try await firestore.updateTaskStatus(
                taskId: task.id,
                status: status,
                propertyId: propertyId,
                resolvedAt: resolvedAt)
            // Update local state immediately for responsiveness
            if let idx = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[idx].status = status
                tasks[idx].resolvedAt = resolvedAt
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addTask(_ task: MaintenanceTask, propertyId: String) async {
        do {
            try await firestore.saveMaintenanceTask(task, propertyId: propertyId)
            await fetchTasks(propertyId: propertyId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: MaintenanceTask, propertyId: String) async {
        do {
            try await firestore.deleteMaintenanceTask(id: task.id, propertyId: propertyId)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
