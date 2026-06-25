import SwiftUI

struct SettingsView: View {
    private let auth = AuthService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Sign Out") {
                        try? auth.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
