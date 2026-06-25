import Foundation

@Observable
class RentViewModel {
    var rentRecords: [RentRecord] = []
    var isLoading = false
    var errorMessage: String?
}
