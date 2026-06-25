import Foundation
import FirebaseFirestore

class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private init() {
        // Offline persistence is enabled by default in Firebase iOS SDK 10+
        // No settings configuration needed
    }

    private func propertyRef(_ propertyId: String) -> DocumentReference {
        db.collection("properties").document(propertyId)
    }

    // MARK: - Rooms

    func fetchRooms(propertyId: String) async throws -> [Room] {
        let snap = try await propertyRef(propertyId).collection("rooms").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Room.self) }
    }

    func saveRoom(_ room: Room, propertyId: String) async throws {
        try propertyRef(propertyId).collection("rooms").document(room.id).setData(from: room)
    }

    func deleteRoom(id: String, propertyId: String) async throws {
        try await propertyRef(propertyId).collection("rooms").document(id).delete()
    }

    func updateRoomStatus(id: String, propertyId: String, status: Room.RoomStatus) async throws {
        try await propertyRef(propertyId).collection("rooms").document(id)
            .updateData(["status": status.rawValue])
    }

    // MARK: - Tenants

    func fetchTenants(propertyId: String) async throws -> [Tenant] {
        let snap = try await propertyRef(propertyId).collection("tenants").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: Tenant.self) }
    }

    func saveTenant(_ tenant: Tenant, propertyId: String) async throws {
        try propertyRef(propertyId).collection("tenants").document(tenant.id).setData(from: tenant)
    }

    func deleteTenant(id: String, propertyId: String) async throws {
        try await propertyRef(propertyId).collection("tenants").document(id).delete()
    }

    // MARK: - Rent Records

    func fetchRentRecords(propertyId: String, month: Int, year: Int) async throws -> [RentRecord] {
        let snap = try await propertyRef(propertyId).collection("rentRecords")
            .whereField("month", isEqualTo: month)
            .whereField("year", isEqualTo: year)
            .getDocuments()
        return snap.documents.compactMap { try? $0.data(as: RentRecord.self) }
    }

    func fetchAllRentRecords(propertyId: String) async throws -> [RentRecord] {
        let snap = try await propertyRef(propertyId).collection("rentRecords").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: RentRecord.self) }
    }

    func saveRentRecord(_ record: RentRecord, propertyId: String) async throws {
        try propertyRef(propertyId).collection("rentRecords").document(record.id).setData(from: record)
    }

    // MARK: - Maintenance

    func fetchMaintenanceTasks(propertyId: String) async throws -> [MaintenanceTask] {
        let snap = try await propertyRef(propertyId).collection("maintenance").getDocuments()
        return snap.documents.compactMap { try? $0.data(as: MaintenanceTask.self) }
    }

    func saveMaintenanceTask(_ task: MaintenanceTask, propertyId: String) async throws {
        try propertyRef(propertyId).collection("maintenance").document(task.id).setData(from: task)
    }

    func deleteMaintenanceTask(id: String, propertyId: String) async throws {
        try await propertyRef(propertyId).collection("maintenance").document(id).delete()
    }

    // MARK: - Property

    func updateProperty(propertyId: String, name: String, address: String, totalRooms: Int) async throws {
        try await propertyRef(propertyId).updateData([
            "name": name,
            "address": address,
            "totalRooms": totalRooms
        ])
    }
}
