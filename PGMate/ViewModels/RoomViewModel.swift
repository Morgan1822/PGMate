import Foundation
import FirebaseCrashlytics

@Observable
class RoomViewModel {
    var rooms: [Room] = []
    var isLoading = false
    var errorMessage: String?
    var selectedFilter: RoomFilter = .all

    enum RoomFilter: String, CaseIterable {
        case all = "All"
        case vacant = "Vacant"
        case occupied = "Occupied"
        case maintenance = "Maintenance"
    }

    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared

    var filteredRooms: [Room] {
        switch selectedFilter {
        case .all: return rooms
        case .vacant: return rooms.filter { $0.status == .vacant }
        case .occupied: return rooms.filter { $0.status == .occupied }
        case .maintenance: return rooms.filter { $0.status == .maintenance }
        }
    }

    var vacantCount: Int { rooms.filter { $0.status == .vacant }.count }
    var occupiedCount: Int { rooms.filter { $0.status == .occupied }.count }
    var maintenanceCount: Int { rooms.filter { $0.status == .maintenance }.count }

    func load() async {
        guard let propertyId = auth.currentPropertyId else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            rooms = try await firestore
                .fetchRooms(propertyId: propertyId)
                .sorted { $0.roomNumber < $1.roomNumber }
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
        }
    }

    func updateStatus(room: Room, status: Room.RoomStatus) async {
        guard let propertyId = auth.currentPropertyId else { return }
        do {
            try await firestore.updateRoomStatus(
                id: room.id, propertyId: propertyId, status: status)
            await load()
        } catch {
            Crashlytics.crashlytics().record(error: error)
            errorMessage = error.localizedDescription
        }
    }
}
