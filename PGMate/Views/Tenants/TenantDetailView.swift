import SwiftUI

struct TenantDetailView: View {
    let tenant: Tenant
    let viewModel: TenantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCheckOutAlert = false
    @State private var isCheckingOut = false
    // ID Proof photo
    @State private var proofImage: UIImage?
    @State private var proofFromPicker: UIImage?
    @State private var showProofFullScreen = false
    @State private var showProofOptions = false
    @State private var showProofCamera = false
    @State private var showProofLibrary = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: Avatar header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.navyPrimary.opacity(0.12))
                                    .frame(width: 80, height: 80)
                                if let data = UserDefaults.standard.data(
                                    forKey: "tenant_photo_\(tenant.id)"),
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                } else {
                                    Text(tenant.initials)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundStyle(Color.navyPrimary)
                                }
                            }
                            Text(tenant.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            StatusBadge(
                                text: tenant.status == .active ? "Active" : "Checked Out",
                                color: tenant.status == .active ? .positive : .textSecondary
                            )
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: Contact
                Section("Contact") {
                    if let url = URL(string: "tel:\(tenant.phone)") {
                        Link(destination: url) {
                            Label(tenant.phone, systemImage: "phone.fill")
                        }
                    }
                    if let url = URL(string: "mailto:\(tenant.email)") {
                        Link(destination: url) {
                            Label(tenant.email, systemImage: "envelope.fill")
                        }
                    }
                }

                // MARK: Stay details
                Section("Stay Details") {
                    LabeledContent("Room", value: tenant.roomNumber)
                    LabeledContent("Check-in", value: tenant.checkInDate.formatted(
                        .dateTime.day().month(.wide).year()))
                    LabeledContent("Duration", value: "\(tenant.monthsStayed) months")
                    LabeledContent("ID Proof", value: tenant.idProofType.displayName)
                }

                // MARK: Financials
                Section("Financials") {
                    LabeledContent("Monthly Rent", value: formatINR(tenant.monthlyRent))
                    LabeledContent("Deposit Paid", value: formatINR(tenant.depositAmount))
                }

                // MARK: Emergency contact
                Section("Emergency Contact") {
                    LabeledContent("Name", value: tenant.emergencyContactName)
                    if let url = URL(string: "tel:\(tenant.emergencyContactPhone)") {
                        Link(destination: url) {
                            Label(tenant.emergencyContactPhone, systemImage: "phone.fill")
                        }
                    }
                }

                // MARK: ID Proof Photo
                Section("ID Proof") {
                    if let proof = proofImage {
                        Button(action: { showProofFullScreen = true }) {
                            Image(uiImage: proof)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .clipped()
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } else {
                        HStack {
                            Text("No proof submitted")
                                .font(.caption)
                                .foregroundStyle(Color.textSecondary)
                            Spacer()
                            Button(action: { showProofOptions = true }) {
                                Label("Add", systemImage: "camera.fill")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.gold)
                            }
                        }
                    }
                }
                .listRowBackground(Color.surface)

                // MARK: Check out
                if tenant.status == .active {
                    Section {
                        Button(role: .destructive, action: { showCheckOutAlert = true }) {
                            HStack {
                                Spacer()
                                if isCheckingOut {
                                    ProgressView()
                                } else {
                                    Label("Check Out Tenant", systemImage: "door.right.hand.open")
                                }
                                Spacer()
                            }
                        }
                    } footer: {
                        Text("Deposit refund: \(formatINR(tenant.depositAmount))")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Tenant")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if let data = UserDefaults.standard.data(forKey: "tenant_proof_\(tenant.id)"),
                   let img = UIImage(data: data) {
                    proofImage = img
                }
            }
            .onChange(of: proofFromPicker) { _, newValue in
                guard let newValue else { return }
                proofImage = newValue
                if let data = newValue.jpegData(compressionQuality: 0.7) {
                    UserDefaults.standard.set(data, forKey: "tenant_proof_\(tenant.id)")
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
            .sheet(isPresented: $showProofCamera) {
                ImagePicker(selectedImage: $proofFromPicker, sourceType: .camera)
            }
            .sheet(isPresented: $showProofLibrary) {
                ImagePicker(selectedImage: $proofFromPicker, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showProofFullScreen) {
                if let proof = proofImage {
                    FullScreenPhotoView(image: proof, title: "ID Proof")
                }
            }
            .alert("Check Out \(tenant.name)?", isPresented: $showCheckOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Check Out", role: .destructive) {
                    isCheckingOut = true
                    Task {
                        try? await viewModel.checkOut(tenant: tenant)
                        await MainActor.run {
                            isCheckingOut = false
                            dismiss()
                        }
                    }
                }
            } message: {
                Text("This will mark the tenant as checked out and set room \(tenant.roomNumber) to vacant. Deposit refund: \(formatINR(tenant.depositAmount))")
            }
        }
    }
}

// MARK: - FullScreenPhotoView

struct FullScreenPhotoView: View {
    let image: UIImage
    let title: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.gold)
                            .font(.title3)
                    }
                }
            }
        }
    }
}
