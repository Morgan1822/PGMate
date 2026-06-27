import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    private let auth = AuthService.shared

    @State private var showSignOutAlert = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var deletionError: String?
    @State private var showDeletionError = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        ZStack {
            List {
                // MARK: Account
                Section("Account") {
                    LabeledContent("Name", value: auth.ownerName.isEmpty ? "—" : auth.ownerName)
                    LabeledContent("Email", value: Auth.auth().currentUser?.email ?? "—")
                    LabeledContent("Property", value: auth.propertyName.isEmpty ? "—" : auth.propertyName)
                }
                .listRowBackground(Color.surface)

                // MARK: App
                Section("App") {
                    LabeledContent("Version", value: appVersion)
                }
                .listRowBackground(Color.surface)

                // MARK: Danger Zone
                Section("Danger Zone") {
                    Button {
                        showSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(Color.textSecondary)
                    }

                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Account", systemImage: "trash.fill")
                    }
                }
                .listRowBackground(Color.surface)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.bgSecondary.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navyNavBar()
            .alert("Sign Out?", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    try? auth.signOut()
                }
            } message: {
                Text("You will need to sign in again.")
            }
            .alert("Delete Account?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    Task { await performDeletion() }
                }
            } message: {
                Text("This will permanently delete your account and ALL property data. This cannot be undone.")
            }
            .alert("Deletion Failed", isPresented: $showDeletionError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deletionError ?? "Please try again.")
            }

            // Deletion progress overlay
            if isDeleting {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.4)
                    Text("Deleting account…")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(32)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private func performDeletion() async {
        guard let user = Auth.auth().currentUser,
              let propertyId = auth.currentPropertyId else {
            deletionError = "Could not find account data."
            showDeletionError = true
            return
        }

        await MainActor.run { isDeleting = true }

        do {
            try await FirestoreService.shared.deleteAllOwnerData(
                propertyId: propertyId,
                uid: user.uid
            )
            try await user.delete()
            // Auth state listener in AuthService will set isAuthenticated = false,
            // which causes RootView to switch back to SignInView automatically.
        } catch {
            await MainActor.run {
                isDeleting = false
                deletionError = error.localizedDescription
                showDeletionError = true
            }
        }
    }
}
