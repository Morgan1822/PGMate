import Foundation

@Observable
class MaintenanceViewModel {
    var tasks: [MaintenanceTask] = []
    var isLoading = false
    var errorMessage: String?
}
