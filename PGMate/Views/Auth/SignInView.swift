import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false
    @State private var showPassword = false

    private var auth: AuthService { AuthService.shared }

    var body: some View {
        NavigationStack {
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

                            Text("Smart PG Management")
                                .font(.subheadline)
                                .foregroundStyle(Color.gold)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)

                        // MARK: Fields
                        VStack(spacing: 14) {
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
                                contentType: .password
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

                            // Sign In button
                            Button {
                                Task { await signIn() }
                            } label: {
                                Group {
                                    if isLoading {
                                        HStack(spacing: 10) {
                                            ProgressView().tint(Color(hex: "#1A3566"))
                                            Text("Signing in...")
                                                .font(.system(size: 17, weight: .bold))
                                        }
                                    } else {
                                        Text("Sign In")
                                            .font(.system(size: 17, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.gold)
                                .foregroundStyle(Color.navyDark)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                            .padding(.top, 4)
                        }
                        .padding(.horizontal, 24)

                        // Sign Up link
                        Button {
                            showSignUp = true
                        } label: {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundStyle(Color.white.opacity(0.7))
                                Text("Sign Up")
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
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationBarHidden(true)
        }
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

    // MARK: - Sign In Action

    private func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
