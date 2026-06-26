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
            ScrollView {
                VStack(spacing: 32) {
                    // MARK: Logo
                    VStack(spacing: 12) {
                        if UIImage(named: "PGMateLogo") != nil {
                            Image("PGMateLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.primaryIndigo)
                                    .frame(width: 90, height: 90)
                                Image(systemName: "building.2.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.accentGold)
                            }
                            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        }

                        Text("PGMate")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.textDark)

                        Text("PG Management, simplified.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 48)

                    // MARK: Fields
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(.password)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // MARK: Error
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // MARK: Sign In Button
                    Button {
                        Task { await signIn() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Sign In")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryIndigo)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isLoading || email.isEmpty || password.isEmpty)

                    // MARK: Sign Up Link
                    Button {
                        showSignUp = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.primaryIndigo)
                        }
                        .font(.subheadline)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
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
