import Foundation
import FirebaseFirestore
import FirebaseStorage

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
        var data: [String: Any] = [
            "id": tenant.id,
            "roomId": tenant.roomId,
            "roomNumber": tenant.roomNumber,
            "name": tenant.name,
            "phone": tenant.phone,
            "email": tenant.email,
            "idProofType": tenant.idProofType.rawValue,
            "checkInDate": Timestamp(date: tenant.checkInDate),
            "depositAmount": tenant.depositAmount,
            "monthlyRent": tenant.monthlyRent,
            "status": tenant.status.rawValue,
            "emergencyContactName": tenant.emergencyContactName,
            "emergencyContactPhone": tenant.emergencyContactPhone
        ]
        if let photoURL = tenant.photoURL {
            data["photoURL"] = photoURL
        }
        if let checkOutDate = tenant.checkOutDate {
            data["checkOutDate"] = Timestamp(date: checkOutDate)
        }
        try await propertyRef(propertyId)
            .collection("tenants")
            .document(tenant.id).setData(data)
    }

    func uploadTenantPhoto(photoData: Data, tenantId: String, propertyId: String) async throws -> String {
        let storage = Storage.storage()
        let ref = storage.reference()
            .child("tenants/\(propertyId)/\(tenantId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(photoData, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
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
        var data: [String: Any] = [
            "id": record.id,
            "tenantId": record.tenantId,
            "tenantName": record.tenantName,
            "roomNumber": record.roomNumber,
            "month": record.month,
            "year": record.year,
            "amount": record.amount,
            "dueDate": Timestamp(date: record.dueDate),
            "status": record.status.rawValue,
            "paymentMethod": record.paymentMethod.rawValue
        ]
        if let paidDate = record.paidDate {
            data["paidDate"] = Timestamp(date: paidDate)
        }
        if let upiId = record.upiTransactionId {
            data["upiTransactionId"] = upiId
        }
        try await propertyRef(propertyId)
            .collection("rentRecords")
            .document(record.id).setData(data)
    }

    // MARK: - Maintenance

    func fetchMaintenanceTasks(propertyId: String) async throws -> [MaintenanceTask] {
        let snap = try await propertyRef(propertyId).collection("maintenance").getDocuments()

        return snap.documents.compactMap { doc in
            let data = doc.data()
            let id = data["id"] as? String ?? doc.documentID
            guard let title = data["title"] as? String else { return nil }

            let description = data["description"] as? String ?? ""

            // roomNumber may be Int or String or nil
            let roomNumber: String
            if let rn = data["roomNumber"] as? String {
                roomNumber = rn
            } else if let rn = data["roomNumber"] as? Int {
                roomNumber = String(rn)
            } else {
                roomNumber = ""
            }

            // status: map legacy "pending" to .open
            let statusRaw = data["status"] as? String ?? "open"
            let status: MaintenanceTask.TaskStatus
            if statusRaw == "pending" {
                status = .open
            } else {
                status = MaintenanceTask.TaskStatus(rawValue: statusRaw) ?? .open
            }

            // priority: default medium if missing
            let priorityRaw = data["priority"] as? String ?? "medium"
            let priority = MaintenanceTask.Priority(rawValue: priorityRaw) ?? .medium

            // estimatedCost may be Int or Double
            let estimatedCost = data["estimatedCost"] as? Double
                ?? Double(data["estimatedCost"] as? Int ?? 0)

            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                ?? (data["scheduledDate"] as? Timestamp)?.dateValue()
                ?? Date()
            let resolvedAt = (data["resolvedAt"] as? Timestamp)?.dateValue()
                ?? (data["completedDate"] as? Timestamp)?.dateValue()

            return MaintenanceTask(
                id: id,
                propertyId: propertyId,
                roomNumber: roomNumber,
                title: title,
                description: description,
                status: status,
                priority: priority,
                estimatedCost: estimatedCost,
                createdAt: createdAt,
                resolvedAt: resolvedAt
            )
        }
    }

    func saveMaintenanceTask(_ task: MaintenanceTask, propertyId: String) async throws {
        var data: [String: Any] = [
            "id": task.id,
            "propertyId": task.propertyId,
            "roomNumber": task.roomNumber,
            "title": task.title,
            "description": task.description,
            "status": task.status.rawValue,
            "priority": task.priority.rawValue,
            "estimatedCost": task.estimatedCost,
            "createdAt": Timestamp(date: task.createdAt)
        ]
        if let resolvedAt = task.resolvedAt {
            data["resolvedAt"] = Timestamp(date: resolvedAt)
        }
        try await propertyRef(propertyId)
            .collection("maintenance")
            .document(task.id).setData(data)
    }

    func updateTaskStatus(taskId: String, status: MaintenanceTask.TaskStatus, propertyId: String, resolvedAt: Date?) async throws {
        var data: [String: Any] = ["status": status.rawValue]
        if let resolvedAt = resolvedAt {
            data["resolvedAt"] = Timestamp(date: resolvedAt)
        }
        try await propertyRef(propertyId)
            .collection("maintenance")
            .document(taskId).updateData(data)
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
