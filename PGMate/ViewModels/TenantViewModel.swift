import Foundation

@Observable
class TenantViewModel {
    var tenants: [Tenant] = []
    var isLoading = false
    var errorMessage: String?
}
