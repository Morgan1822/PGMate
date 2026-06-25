import Foundation

@Observable
class RoomViewModel {
    var rooms: [Room] = []
    var isLoading = false
    var errorMessage: String?
}
