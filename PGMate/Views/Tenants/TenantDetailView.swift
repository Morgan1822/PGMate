import SwiftUI

struct TenantDetailView: View {
    let tenant: Tenant
    let viewModel: TenantViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCheckOutAlert = false
    @State private var isCheckingOut = false

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
                                    .fill(Color.primaryIndigo.opacity(0.12))
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
                                        .foregroundColor(.primaryIndigo)
                                }
                            }
                            Text(tenant.name)
                                .font(.title3)
                                .fontWeight(.bold)
                            StatusBadge(
                                text: tenant.status == .active ? "Active" : "Checked Out",
                                color: tenant.status == .active ? .successGreen : .secondary
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
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
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
