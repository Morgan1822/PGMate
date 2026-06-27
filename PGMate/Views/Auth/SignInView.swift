import SwiftUI

struct SignInView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignUp = false

    private var auth: AuthService { AuthService.shared }

    var body: some View {
        NavigationStack {
            ZStack {
                // Full-screen gradient background
                LinearGradient(
                    colors: [Color.navyDark, Color.navyPrimary, Color.navyLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 36) {
                        // MARK: Logo
                        VStack(spacing: 14) {
                            ZStack {
                                if UIImage(named: "PGMateLogo") != nil {
                                    Image("PGMateLogo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 90, height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 22))
                                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                                } else {
                                    RoundedRectangle(cornerRadius: 22)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 90, height: 90)
                                        .overlay(
                                            Image(systemName: "building.2.fill")
                                                .font(.system(size: 40))
                                                .foregroundStyle(Color.gold)
                                        )
                                        .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                                }
                            }

                            Text("PGMate")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(Color.white)

                            Text("PG Management, simplified.")
                                .font(.subheadline)
                                .foregroundStyle(Color.white.opacity(0.7))
                        }
                        .padding(.top, 60)

                        // MARK: Form card
                        VStack(spacing: 16) {
                            // Email field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.white.opacity(0.8))

                                TextField("you@example.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
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

                            // Password field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(Color.white.opacity(0.8))

                                SecureField("••••••••", text: $password)
                                    .textContentType(.password)
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

                            // Error message
                            if let error = errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(Color.negative)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                            }

                            // Sign In button
                            Button {
                                Task { await signIn() }
                            } label: {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .tint(Color.navyDark)
                                    } else {
                                        Text("Sign In")
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
                            .disabled(isLoading || email.isEmpty || password.isEmpty)
                            .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                            .padding(.top, 8)
                        }
                        .padding(24)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )

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

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .navigationBarHidden(true)
        }
    }

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
