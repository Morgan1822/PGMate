import SwiftUI
import FirebaseFirestore

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var propertyName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var auth: AuthService { AuthService.shared }

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && password.count >= 6
            && passwordsMatch && !propertyName.isEmpty
    }

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                colors: [Color.navyDark, Color.navyPrimary, Color.navyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // MARK: Header
                    VStack(spacing: 10) {
                        Text("Create Account")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.white)

                        Text("Set up your PG management profile")
                            .font(.subheadline)
                            .foregroundStyle(Color.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // MARK: Form
                    VStack(spacing: 16) {
                        signUpField("Full Name", placeholder: "Your name", text: $name,
                                    contentType: .name, keyboard: .default)

                        signUpField("Email", placeholder: "you@example.com", text: $email,
                                    contentType: .emailAddress, keyboard: .emailAddress,
                                    autocap: false)

                        signUpField("Property Name", placeholder: "e.g. Sunrise PG", text: $propertyName,
                                    contentType: .organizationName, keyboard: .default)

                        secureSignUpField("Password", placeholder: "Min. 6 characters", text: $password,
                                          contentType: .newPassword)

                        secureSignUpField("Confirm Password", placeholder: "Re-enter password",
                                          text: $confirmPassword, contentType: .newPassword)

                        // Password mismatch warning
                        if !confirmPassword.isEmpty && !passwordsMatch {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Passwords do not match")
                            }
                            .font(.caption)
                            .foregroundStyle(Color.goldLight)
                        }

                        // General error
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(Color.goldLight)
                                .multilineTextAlignment(.center)
                        }

                        // Create Account button
                        Button {
                            Task { await signUp() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(Color.navyDark)
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.bold)
                                        .font(.system(size: 17))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gold)
                            .foregroundStyle(Color.textOnGold)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.gold.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )

                    // Back to Sign In
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .foregroundStyle(Color.white.opacity(0.7))
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.gold)
                        }
                        .font(.subheadline)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Field builders

    @ViewBuilder
    private func signUpField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType,
        autocap: Bool = true
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.8))

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textContentType(contentType)
                .autocapitalization(autocap ? .words : .none)
                .foregroundStyle(Color.white)
                .tint(Color.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private func secureSignUpField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.white.opacity(0.8))

            SecureField(placeholder, text: text)
                .textContentType(contentType)
                .foregroundStyle(Color.white)
                .tint(Color.gold)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        }
    }

    // MARK: - Sign Up Action

    private func signUp() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signUp(name: name, email: email, password: password)
            // Update the property name in Firestore after account creation
            if let propertyId = auth.currentPropertyId, !propertyName.isEmpty {
                let db = Firestore.firestore()
                try await db.collection("properties").document(propertyId)
                    .updateData(["name": propertyName])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
