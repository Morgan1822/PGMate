import SwiftUI
import Contacts

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
    // Profile photo
    @State private var selectedImage: UIImage?
    @State private var showPhotoOptions = false
    @State private var showCamera = false
    @State private var showLibrary = false
    // ID Proof photo
    @State private var proofImage: UIImage?
    @State private var showProofOptions = false
    @State private var showProofCamera = false
    @State private var showProofLibrary = false

    @State private var vacantRooms: [Room] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showContactSavedToast = false
    @State private var nameError = ""
    @State private var phoneError = ""

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Profile Photo
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button(action: { showPhotoOptions = true }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.bgSecondary)
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Circle().stroke(
                                                Color.navyPrimary.opacity(0.3),
                                                lineWidth: 2)
                                        )
                                    if let photo = selectedImage {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 90, height: 90)
                                            .clipShape(Circle())
                                    } else {
                                        VStack(spacing: 4) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 24))
                                                .foregroundStyle(Color.navyPrimary)
                                            Text("Add Photo")
                                                .font(.caption2)
                                                .foregroundStyle(Color.navyPrimary)
                                        }
                                    }
                                }
                            }
                            .confirmationDialog(
                                "Add Photo",
                                isPresented: $showPhotoOptions,
                                titleVisibility: .visible
                            ) {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    Button("Take Photo") { showCamera = true }
                                }
                                Button("Choose from Library") { showLibrary = true }
                                Button("Cancel", role: .cancel) {}
                            }
                            if selectedImage != nil {
                                Button("Change Photo") { showPhotoOptions = true }
                                    .font(.caption)
                                    .foregroundStyle(Color.navyPrimary)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: ID Proof Photo
                Section("ID Proof (Aadhaar / Any ID)") {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Button(action: { showProofOptions = true }) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.bgSecondary)
                                        .frame(width: 200, height: 110)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12).stroke(
                                                Color.navyPrimary.opacity(0.3), lineWidth: 2)
                                        )
                                    if let proof = proofImage {
                                        Image(uiImage: proof)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 110)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        VStack(spacing: 6) {
                                            Image(systemName: "doc.viewfinder")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Color.navyPrimary)
                                            Text("Add ID Proof")
                                                .font(.caption2)
                                                .foregroundStyle(Color.navyPrimary)
                                        }
                                    }
                                }
                            }
                            .confirmationDialog(
                                "Add ID Proof",
                                isPresented: $showProofOptions,
                                titleVisibility: .visible
                            ) {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    Button("Take Photo") { showProofCamera = true }
                                }
                                Button("Choose from Library") { showProofLibrary = true }
                                Button("Cancel", role: .cancel) {}
                            }
                            if proofImage != nil {
                                Button("Change Proof") { showProofOptions = true }
                                    .font(.caption)
                                    .foregroundStyle(Color.navyPrimary)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: Personal details
                Section("Personal Details") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Full Name", text: $name)
                        if !nameError.isEmpty {
                            Text(nameError).font(.caption).foregroundStyle(Color.negative)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Phone Number", text: $phone)
                            .keyboardType(.phonePad)
                        if !phoneError.isEmpty {
                            Text(phoneError).font(.caption).foregroundStyle(Color.negative)
                        }
                    }
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
                            .foregroundStyle(Color.negative)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Tenant")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
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
            // Profile photo sheets
            .sheet(isPresented: $showCamera) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
            }
            // Proof photo sheets
            .sheet(isPresented: $showProofCamera) {
                ImagePicker(selectedImage: $proofImage, sourceType: .camera)
            }
            .sheet(isPresented: $showProofLibrary) {
                ImagePicker(selectedImage: $proofImage, sourceType: .photoLibrary)
            }
            .task { await loadVacantRooms() }
            .overlay(alignment: .top) {
                if showContactSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                        Text("Added to Contacts")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.positive, in: Capsule())
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.4), value: showContactSavedToast)
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
        nameError = ""
        phoneError = ""
        if let err = Validators.validateName(name) {
            nameError = err.localizedDescription
        }
        if let err = Validators.validatePhoneNumber(phone) {
            phoneError = err.localizedDescription
        }
        guard nameError.isEmpty && phoneError.isEmpty else { return }

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

        // Save profile photo
        if let imageData = selectedImage?.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(imageData, forKey: "tenant_photo_\(tenant.id)")
        }
        // Save ID proof photo
        if let proofData = proofImage?.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(proofData, forKey: "tenant_proof_\(tenant.id)")
        }

        Task {
            do {
                try await viewModel.addTenant(tenant, photoData: nil)
                await MainActor.run {
                    saveToContacts(tenant)
                    showContactSavedToast = true
                }
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run { dismiss() }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func saveToContacts(_ tenant: Tenant) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            guard granted else { return }
            let contact = CNMutableContact()
            contact.givenName = tenant.name
            contact.phoneNumbers = [
                CNLabeledValue(label: CNLabelPhoneNumberMain,
                               value: CNPhoneNumber(stringValue: tenant.phone))
            ]
            let propName = AuthService.shared.propertyName
            contact.organizationName = propName.isEmpty ? "Hostel" : "\(propName) Hostel"
            contact.note = "Tenant ID: \(tenant.id)"
            let request = CNSaveRequest()
            request.add(contact, toContainerWithIdentifier: nil)
            try? store.execute(request)
        }
    }
}
