import SwiftUI

struct AddTenantView: View {
    let viewModel: TenantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var email = ""
    @State private var selectedRoom: Room?
    @State private var idProofType = Tenant.IDProofType.aadhaar
    @State private var checkInDate = Date()
    @State private var depositAmount = ""
    @State private var monthlyRent = ""
    @State private var emergencyName = ""
    @State private var emergencyPhone = ""
    @State private var capturedPhoto: UIImage?
    @State private var showCamera = false
    @State private var vacantRooms: [Room] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Photo
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button(action: { showCamera = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.backgroundLight)
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Circle().stroke(
                                                Color.primaryIndigo.opacity(0.3),
                                                lineWidth: 2)
                                        )
                                    if let photo = capturedPhoto {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                                .foregroundColor(.primaryIndigo)
                                            Text("Add Photo")
                                                .font(.caption2)
                                                .foregroundColor(.primaryIndigo)
                                        }
                                    }
                                }
                            }
                            if capturedPhoto != nil {
                                Button("Retake") {
                                    capturedPhoto = nil
                                    showCamera = true
                                }
                                .font(.caption)
                                .foregroundColor(.primaryIndigo)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: Personal details
                Section("Personal Details") {
                    TextField("Full Name", text: $name)
                    TextField("Phone Number", text: $phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    Picker("ID Proof Type", selection: $idProofType) {
                        ForEach(Tenant.IDProofType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                // MARK: Room & stay
                Section("Room & Stay") {
                    Picker("Room", selection: $selectedRoom) {
                        Text("Select Room").tag(nil as Room?)
                        ForEach(vacantRooms) { room in
                            Text("Room \(room.roomNumber) - \(room.type.displayName)")
                                .tag(room as Room?)
                        }
                    }
                    DatePicker("Check-in Date",
                        selection: $checkInDate,
                        displayedComponents: .date)
                    TextField("Monthly Rent (₹)", text: $monthlyRent)
                        .keyboardType(.numberPad)
                    TextField("Deposit Amount (₹)", text: $depositAmount)
                        .keyboardType(.numberPad)
                }

                // MARK: Emergency contact
                Section("Emergency Contact") {
                    TextField("Contact Name", text: $emergencyName)
                    TextField("Contact Phone", text: $emergencyPhone)
                        .keyboardType(.phonePad)
                }

                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Tenant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveTenant() }
                        .fontWeight(.semibold)
                        .disabled(!canSave || isLoading)
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $capturedPhoto)
            }
            .task { await loadVacantRooms() }
        }
    }

    var canSave: Bool {
        !name.isEmpty && !phone.isEmpty &&
        selectedRoom != nil &&
        Double(monthlyRent) != nil &&
        Double(depositAmount) != nil
    }

    func loadVacantRooms() async {
        guard let propertyId = AuthService.shared.currentPropertyId else { return }
        let rooms = try? await FirestoreService.shared.fetchRooms(propertyId: propertyId)
        vacantRooms = rooms?.filter { $0.status == .vacant } ?? []
        if let room = vacantRooms.first {
            selectedRoom = room
            monthlyRent = String(Int(room.monthlyRent))
        }
    }

    func saveTenant() {
        guard let room = selectedRoom,
              let rent = Double(monthlyRent),
              let deposit = Double(depositAmount),
              let propertyId = AuthService.shared.currentPropertyId
        else { return }

        isLoading = true
        let tenant = Tenant(
            id: UUID().uuidString,
            propertyId: propertyId,
            roomId: room.id,
            roomNumber: room.roomNumber,
            name: name,
            phone: phone,
            email: email,
            idProofType: idProofType,
            checkInDate: checkInDate,
            checkOutDate: nil,
            depositAmount: deposit,
            monthlyRent: rent,
            status: .active,
            emergencyContactName: emergencyName,
            emergencyContactPhone: emergencyPhone,
            photoURL: nil
        )

        let photoData = capturedPhoto?.jpegData(compressionQuality: 0.8)

        Task {
            do {
                try await viewModel.addTenant(tenant, photoData: photoData)
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
