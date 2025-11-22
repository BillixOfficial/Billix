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
            // Enhanced green gradient background
            LinearGradient(
                colors: [
                    Color.billixLoginGreen,
                    Color.billixLoginGreen.opacity(0.85),
                    Color.billixLoginGreen
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                hideKeyboard()
                focusedField = nil
            }

            // Subtle overlay for depth
            RadialGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Logo and branding section
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image("billix_logo_new")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 140, height: 140)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                    Text("Billix")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.billixLoginTeal)
                }

                Spacer()
                    .frame(height: 48)

                // Login form
                VStack(spacing: DesignSystem.Spacing.sm) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(DesignSystem.CornerRadius.standard)

                    // Divider
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: DesignSystem.Typography.Size.caption))
                            .foregroundColor(.gray)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, DesignSystem.Spacing.xxs)

                    // Email
                    TextField("Email", text: $email)
                        .focused($focusedField, equals: .email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                        .padding(DesignSystem.Spacing.sm)
                        .background(Color.white)
                        .cornerRadius(DesignSystem.CornerRadius.standard)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
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
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge))

                        Button(action: {
                            withAnimation(DesignSystem.Animation.spring) {
                                isSecured.toggle()
                            }
                        }) {
                            Image(systemName: isSecured ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(DesignSystem.Spacing.sm)
                    .background(Color.white)
                    .cornerRadius(DesignSystem.CornerRadius.standard)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            // UI only
                        }
                        .font(.system(size: DesignSystem.Typography.Size.caption, weight: .medium))
                        .foregroundColor(.billixLoginTeal)
                    }

                    // Sign In Button
                    Button(action: {
                        handleLogin()
                    }) {
                        Text("Sign In")
                            .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.billixLoginTeal)
                            .cornerRadius(DesignSystem.CornerRadius.standard)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, DesignSystem.Spacing.xxs)
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)

                Spacer()

                // Sign up
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: DesignSystem.Typography.Size.body))
                        .foregroundColor(.gray)

                    Button("Sign up") {
                        // UI only
                    }
                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .semibold))
                    .foregroundColor(.billixLoginTeal)
                }
                .padding(.bottom, 30)
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

            withAnimation(DesignSystem.Animation.spring) {
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
        withAnimation(DesignSystem.Animation.spring) {
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
