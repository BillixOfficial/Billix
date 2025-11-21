import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var isLoggedIn = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            // Simple background
            Color.billixLoginGreen
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                    focusedField = nil
                }

            VStack(spacing: 0) {
                Spacer()

                // Logo
                Image("billix_logo_new")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 120)

                // Brand
                Text("Billix")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(.billixLoginTeal)
                    .padding(.top, 20)

                Spacer()
                    .frame(height: 48)

                // Content
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(12)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Email
                    TextField("Email", text: $email)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )

                    // Password
                    HStack {
                        Group {
                            if isSecured {
                                SecureField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .textContentType(.password)
                            } else {
                                TextField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                        }

                        Button(action: {
                            withAnimation {
                                isSecured.toggle()
                            }
                        }) {
                            Image(systemName: isSecured ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            // UI only
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.billixLoginTeal)
                    }

                    // Sign In Button
                    Button(action: {
                        handleLogin()
                    }) {
                        Text("Sign In")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.billixLoginTeal)
                            .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Sign up
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)

                    Button("Sign up") {
                        // UI only
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.billixLoginTeal)
                }
                .padding(.bottom, 40)
            }

            // Navigation to MainTabView
            if isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            // In production, validate the credential with your backend
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isLoggedIn = true
            }

        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    private func handleLogin() {
        // Dismiss keyboard
        hideKeyboard()
        focusedField = nil

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Skip validation - allow direct access to app (UI only, no auth)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            isLoggedIn = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
}
