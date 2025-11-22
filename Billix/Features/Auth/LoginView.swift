import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var isLoggedIn = false
    @FocusState private var focusedField: Field?

    // Animation states
    @State private var logoScale: CGFloat = 0.8
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            // Premium dark gradient background
            LinearGradient(
                colors: [
                    Color.dsBackgroundPrimary,
                    Color.dsBackgroundSecondary,
                    Color.dsBackgroundPrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                hideKeyboard()
                focusedField = nil
            }

            // Subtle radial glow effect
            RadialGradient(
                colors: [
                    Color.dsPrimaryAccent.opacity(0.15),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Logo with glow effect
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image("billix_logo_new")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .shadow(
                                color: Color.dsPrimaryAccent.opacity(0.5),
                                radius: 30,
                                x: 0,
                                y: 0
                            )
                            .scaleEffect(logoScale)

                        // Brand name
                        Text("Billix")
                            .font(.system(size: DesignSystem.Typography.Size.display, weight: .bold))
                            .foregroundColor(.dsTextPrimary)
                            .shadow(
                                color: Color.dsPrimaryAccent.opacity(0.3),
                                radius: 10,
                                x: 0,
                                y: 5
                            )

                        // Tagline
                        Text("Your Smart Bills Companion")
                            .font(.system(size: DesignSystem.Typography.Size.body))
                            .foregroundColor(.dsTextTertiary)
                            .padding(.top, -DesignSystem.Spacing.xs)
                    }
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                    Spacer()
                        .frame(height: 64)

                    // Login form container
                    VStack(spacing: DesignSystem.Spacing.md) {
                        // Apple Sign In
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(DesignSystem.CornerRadius.standard)
                        .shadow(
                            color: Color.black.opacity(0.2),
                            radius: DesignSystem.Shadow.Medium.radius,
                            x: 0,
                            y: DesignSystem.Shadow.Medium.y
                        )

                        // Divider
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Rectangle()
                                .fill(Color.dsTextTertiary.opacity(0.3))
                                .frame(height: 1)

                            Text("or continue with email")
                                .font(.system(size: DesignSystem.Typography.Size.caption))
                                .foregroundColor(.dsTextTertiary)

                            Rectangle()
                                .fill(Color.dsTextTertiary.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)

                        // Email input
                        ModernTextField(
                            placeholder: "Email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress,
                            focused: $focusedField,
                            fieldType: .email
                        )

                        // Password input
                        ModernSecureField(
                            placeholder: "Password",
                            text: $password,
                            isSecured: $isSecured,
                            focused: $focusedField,
                            fieldType: .password
                        )

                        // Forgot Password
                        HStack {
                            Spacer()
                            Button {
                                // UI only
                                hapticFeedback(.warning)
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .medium))
                                    .foregroundColor(.dsPrimaryAccent)
                            }
                        }
                        .padding(.top, -DesignSystem.Spacing.xxs)

                        // Sign In Button
                        Button {
                            handleLogin()
                        } label: {
                            HStack(spacing: DesignSystem.Spacing.xs) {
                                Text("Sign In")
                                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge, weight: .semibold))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: DesignSystem.Typography.Size.body, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color.dsPrimaryAccent,
                                        Color.dsPrimaryAccent.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(DesignSystem.CornerRadius.standard)
                            .shadow(
                                color: Color.dsPrimaryAccent.opacity(0.4),
                                radius: DesignSystem.Shadow.Medium.radius,
                                x: 0,
                                y: DesignSystem.Shadow.Medium.y
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, DesignSystem.Spacing.xs)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xl)
                    .opacity(contentOpacity)
                    .offset(y: contentOffset)

                    Spacer()
                        .frame(height: 48)

                    // Sign up link
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Text("Don't have an account?")
                            .font(.system(size: DesignSystem.Typography.Size.body))
                            .foregroundColor(.dsTextSecondary)

                        Button {
                            // UI only
                            hapticFeedback(.warning)
                        } label: {
                            Text("Sign up")
                                .font(.system(size: DesignSystem.Typography.Size.body, weight: .semibold))
                                .foregroundColor(.dsPrimaryAccent)
                        }
                    }
                    .opacity(contentOpacity)
                    .padding(.bottom, 40)
                }
            }

            // Navigation to MainTabView
            if isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Entrance animations
            withAnimation(DesignSystem.Animation.spring.delay(0.1)) {
                logoScale = 1.0
            }

            withAnimation(DesignSystem.Animation.smoothSpring.delay(0.2)) {
                contentOpacity = 1.0
                contentOffset = 0
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(_):
            // In production, validate the credential with your backend
            hapticFeedback(.success)

            withAnimation(DesignSystem.Animation.spring) {
                isLoggedIn = true
            }

        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
            hapticFeedback(.error)
        }
    }

    private func handleLogin() {
        // Dismiss keyboard
        hideKeyboard()
        focusedField = nil

        // Haptic feedback
        hapticFeedback(.success)

        // Skip validation - allow direct access to app (UI only, no auth)
        withAnimation(DesignSystem.Animation.spring) {
            isLoggedIn = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Modern Text Field Component

struct ModernTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    @FocusState.Binding var focused: LoginView.Field?
    let fieldType: LoginView.Field

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.dsTextTertiary)
            }
            .focused($focused, equals: fieldType)
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .autocapitalization(.none)
            .disableAutocorrection(true)
            .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
            .foregroundColor(.dsTextPrimary)
            .padding(DesignSystem.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(Color.dsCardBackground.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .stroke(
                        focused == fieldType ?
                            Color.dsPrimaryAccent :
                            Color.white.opacity(DesignSystem.Opacity.backgroundTint),
                        lineWidth: focused == fieldType ? 2 : 1
                    )
            )
            .shadow(
                color: focused == fieldType ?
                    Color.dsPrimaryAccent.opacity(0.2) :
                    Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Modern Secure Field Component

struct ModernSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var isSecured: Bool
    @FocusState.Binding var focused: LoginView.Field?
    let fieldType: LoginView.Field

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Group {
                if isSecured {
                    SecureField("", text: $text)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder)
                                .foregroundColor(.dsTextTertiary)
                        }
                        .focused($focused, equals: fieldType)
                        .textContentType(.password)
                } else {
                    TextField("", text: $text)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder)
                                .foregroundColor(.dsTextTertiary)
                        }
                        .focused($focused, equals: fieldType)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
            }
            .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
            .foregroundColor(.dsTextPrimary)

            Button {
                withAnimation(DesignSystem.Animation.spring) {
                    isSecured.toggle()
                }
            } label: {
                Image(systemName: isSecured ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                    .foregroundColor(.dsTextTertiary)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                .fill(Color.dsCardBackground.opacity(0.6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                .stroke(
                    focused == fieldType ?
                        Color.dsPrimaryAccent :
                        Color.white.opacity(DesignSystem.Opacity.backgroundTint),
                    lineWidth: focused == fieldType ? 2 : 1
                )
        )
        .shadow(
            color: focused == fieldType ?
                Color.dsPrimaryAccent.opacity(0.2) :
                Color.clear,
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Placeholder ViewModifier Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
}
