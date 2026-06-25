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

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let floor = data["floor"] as? Int,
                  let statusRaw = data["status"] as? String,
                  let typeRaw = data["type"] as? String,
                  let status = Room.RoomStatus(rawValue: statusRaw),
                  let type = Room.RoomType(rawValue: typeRaw)
            else { return nil }

            // roomNumber may be Int or String in Firestore
            let roomNumber: String
            if let rn = data["roomNumber"] as? String {
                roomNumber = rn
            } else if let rn = data["roomNumber"] as? Int {
                roomNumber = String(rn)
            } else { return nil }

            // monthlyRent may be Int or Double
            let monthlyRent = data["monthlyRent"] as? Double
                ?? Double(data["monthlyRent"] as? Int ?? 0)

            let amenities = data["amenities"] as? [String] ?? []

            return Room(
                id: id,
                propertyId: propertyId,
                roomNumber: roomNumber,
                floor: floor,
                type: type,
                monthlyRent: monthlyRent,
                status: status,
                amenities: amenities
            )
        }
    }

    func saveRoom(_ room: Room, propertyId: String) async throws {
        try await propertyRef(propertyId).collection("rooms").document(room.id).setData([
            "id": room.id,
            "roomNumber": room.roomNumber,
            "floor": room.floor,
            "type": room.type.rawValue,
            "monthlyRent": room.monthlyRent,
            "status": room.status.rawValue,
            "amenities": room.amenities
        ])
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

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let name = data["name"] as? String,
                  let phone = data["phone"] as? String,
                  let email = data["email"] as? String,
                  let idProofRaw = data["idProofType"] as? String,
                  let idProof = Tenant.IDProofType(rawValue: idProofRaw),
                  let statusRaw = data["status"] as? String,
                  let status = Tenant.TenantStatus(rawValue: statusRaw)
            else { return nil }

            // roomNumber may be Int or String
            let roomNumber: String
            if let rn = data["roomNumber"] as? String {
                roomNumber = rn
            } else if let rn = data["roomNumber"] as? Int {
                roomNumber = String(rn)
            } else { return nil }

            guard let roomId = data["roomId"] as? String else { return nil }

            // checkInDate from Firestore Timestamp
            let checkInDate = (data["checkInDate"] as? Timestamp)?.dateValue() ?? Date()
            let checkOutDate = (data["checkOutDate"] as? Timestamp)?.dateValue()

            // depositAmount and monthlyRent may be Int or Double
            let depositAmount = data["depositAmount"] as? Double
                ?? Double(data["depositAmount"] as? Int ?? 0)
            let monthlyRent = data["monthlyRent"] as? Double
                ?? Double(data["monthlyRent"] as? Int ?? 0)

            let emergencyContactName = data["emergencyContactName"] as? String ?? ""
            let emergencyContactPhone = data["emergencyContactPhone"] as? String ?? ""
            let photoURL = data["photoURL"] as? String

            return Tenant(
                id: id,
                propertyId: propertyId,
                roomId: roomId,
                roomNumber: roomNumber,
                name: name,
                phone: phone,
                email: email,
                idProofType: idProof,
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
                depositAmount: depositAmount,
                monthlyRent: monthlyRent,
                status: status,
                emergencyContactName: emergencyContactName,
                emergencyContactPhone: emergencyContactPhone,
                photoURL: photoURL
            )
        }
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
        return decodeRentRecords(snap.documents, propertyId: propertyId)
    }

    func fetchAllRentRecords(propertyId: String) async throws -> [RentRecord] {
        let snap = try await propertyRef(propertyId).collection("rentRecords").getDocuments()
        return decodeRentRecords(snap.documents, propertyId: propertyId)
    }

    private func decodeRentRecords(_ documents: [QueryDocumentSnapshot], propertyId: String) -> [RentRecord] {
        documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let tenantId = data["tenantId"] as? String,
                  let tenantName = data["tenantName"] as? String,
                  let month = data["month"] as? Int,
                  let year = data["year"] as? Int,
                  let statusRaw = data["status"] as? String,
                  let status = RentRecord.RentStatus(rawValue: statusRaw)
            else { return nil }

            // roomNumber may be Int or String
            let roomNumber: String
            if let rn = data["roomNumber"] as? String {
                roomNumber = rn
            } else if let rn = data["roomNumber"] as? Int {
                roomNumber = String(rn)
            } else { return nil }

            // amount may be Int or Double
            let amount = data["amount"] as? Double
                ?? Double(data["amount"] as? Int ?? 0)

            let dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
            let paidDate = (data["paidDate"] as? Timestamp)?.dateValue()

            let paymentMethodRaw = data["paymentMethod"] as? String ?? "pending"
            let paymentMethod = RentRecord.PaymentMethod(rawValue: paymentMethodRaw) ?? .pending

            let upiTransactionId = data["upiTransactionId"] as? String

            return RentRecord(
                id: id,
                propertyId: propertyId,
                tenantId: tenantId,
                tenantName: tenantName,
                roomNumber: roomNumber,
                month: month,
                year: year,
                amount: amount,
                dueDate: dueDate,
                paidDate: paidDate,
                paymentMethod: paymentMethod,
                upiTransactionId: upiTransactionId,
                status: status
            )
        }
    }

    func saveRentRecord(_ record: RentRecord, propertyId: String) async throws {
        try propertyRef(propertyId).collection("rentRecords").document(record.id).setData(from: record)
    }

    // MARK: - Maintenance

    func fetchMaintenanceTasks(propertyId: String) async throws -> [MaintenanceTask] {
        let snap = try await propertyRef(propertyId).collection("maintenance").getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()
            guard let id = data["id"] as? String,
                  let title = data["title"] as? String,
                  let description = data["description"] as? String,
                  let categoryRaw = data["category"] as? String,
                  let category = MaintenanceTask.MaintenanceCategory(rawValue: categoryRaw),
                  let statusRaw = data["status"] as? String,
                  let status = MaintenanceTask.TaskStatus(rawValue: statusRaw)
            else { return nil }

            // roomNumber may be Int or String or nil
            let roomNumber: String?
            if let rn = data["roomNumber"] as? String {
                roomNumber = rn
            } else if let rn = data["roomNumber"] as? Int {
                roomNumber = String(rn)
            } else {
                roomNumber = nil
            }

            let roomId = data["roomId"] as? String
            let assignedTo = data["assignedTo"] as? String

            // costs may be Int or Double or nil
            let estimatedCost = data["estimatedCost"] as? Double
                ?? (data["estimatedCost"] as? Int).map { Double($0) }
            let actualCost = data["actualCost"] as? Double
                ?? (data["actualCost"] as? Int).map { Double($0) }

            let scheduledDate = (data["scheduledDate"] as? Timestamp)?.dateValue()
            let completedDate = (data["completedDate"] as? Timestamp)?.dateValue()

            return MaintenanceTask(
                id: id,
                propertyId: propertyId,
                roomId: roomId,
                roomNumber: roomNumber,
                title: title,
                description: description,
                category: category,
                status: status,
                assignedTo: assignedTo,
                estimatedCost: estimatedCost,
                actualCost: actualCost,
                scheduledDate: scheduledDate,
                completedDate: completedDate
            )
        }
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
