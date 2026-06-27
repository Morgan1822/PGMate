import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var propertyName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    private var auth: AuthService { AuthService.shared }

    private var passwordsMatch: Bool { password == confirmPassword }
    private var isFormValid: Bool {
        !name.isEmpty && email.contains("@") && password.count >= 6
            && passwordsMatch && !propertyName.isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "#1A3566").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {

                    // MARK: Logo + Branding
                    VStack(spacing: 10) {
                        Image("PGMateLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 4)

                        Text("PGMate")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.white)

                        Text("Create Your Account")
                            .font(.subheadline)
                            .foregroundStyle(Color.gold)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 32)

                    // MARK: Fields
                    VStack(spacing: 14) {
                        authField(
                            icon: "person.fill",
                            placeholder: "Full Name",
                            text: $name,
                            contentType: .name,
                            autocap: true
                        )

                        authField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboard: .emailAddress,
                            contentType: .emailAddress,
                            autocap: false
                        )

                        authPasswordField(
                            placeholder: "Password",
                            text: $password,
                            showPassword: $showPassword,
                            contentType: .newPassword
                        )

                        authPasswordField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            showPassword: $showConfirmPassword,
                            contentType: .newPassword
                        )

                        authField(
                            icon: "building.2.fill",
                            placeholder: "Property Name",
                            text: $propertyName,
                            contentType: .organizationName,
                            autocap: true
                        )

                        // Error pill
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                Text(error)
                                    .font(.caption)
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.negative, in: RoundedRectangle(cornerRadius: 10))
                        }

                        // Create Account button
                        Button {
                            Task { await signUp() }
                        } label: {
                            Group {
                                if isLoading {
                                    ProgressView().tint(Color(hex: "#1A3566"))
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 17, weight: .bold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.gold)
                            .foregroundStyle(Color(hex: "#1A3566"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

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
                    .padding(.top, 32)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Field builders

    @ViewBuilder
    private func authField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default,
        contentType: UITextContentType,
        autocap: Bool = true
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(width: 20)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                TextField("", text: text)
                    .keyboardType(keyboard)
                    .textContentType(contentType)
                    .autocapitalization(autocap ? .words : .none)
                    .foregroundStyle(Color.white)
                    .tint(Color.gold)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func authPasswordField(
        placeholder: String,
        text: Binding<String>,
        showPassword: Binding<Bool>,
        contentType: UITextContentType
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(Color.white.opacity(0.7))
                .frame(width: 20)

            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                if showPassword.wrappedValue {
                    TextField("", text: text)
                        .textContentType(contentType)
                        .foregroundStyle(Color.white)
                        .tint(Color.gold)
                } else {
                    SecureField("", text: text)
                        .textContentType(contentType)
                        .foregroundStyle(Color.white)
                        .tint(Color.gold)
                }
            }

            Button(action: { showPassword.wrappedValue.toggle() }) {
                Image(systemName: showPassword.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Sign Up Action

    private func validate() -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Full name is required."
            return false
        }
        if !email.contains("@") {
            errorMessage = "Enter a valid email address."
            return false
        }
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters."
            return false
        }
        if !passwordsMatch {
            errorMessage = "Passwords do not match."
            return false
        }
        if propertyName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Property name is required."
            return false
        }
        return true
    }

    private func signUp() async {
        guard validate() else { return }
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signUp(
                name: name,
                email: email,
                password: password,
                propertyName: propertyName
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
