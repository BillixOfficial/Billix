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
            // Enhanced green gradient background with depth
            LinearGradient(
                colors: [
                    Color.billixLoginGreen.opacity(0.9),
                    Color.billixLoginGreen,
                    Color.billixLoginGreen.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .onTapGesture {
                hideKeyboard()
                focusedField = nil
            }

            // Subtle overlay for depth (reduced brightness)
            RadialGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear
                ],
                center: .top,
                startRadius: 100,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Wave and line texture patterns
            GeometryReader { geometry in
                ZStack {
                    // Diagonal lines pattern (sandpaper effect)
                    ForEach(0..<50, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 1, height: geometry.size.height * 1.5)
                            .rotationEffect(.degrees(45))
                            .offset(x: CGFloat(i * 15) - 200)
                    }

                    // Wave patterns at top
                    WaveShape(phase: 0)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 120)
                        .offset(y: 100)

                    WaveShape(phase: 0.5)
                        .fill(Color.white.opacity(0.04))
                        .frame(height: 100)
                        .offset(y: 150)

                    // Wave patterns at bottom
                    WaveShape(phase: 0.3)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 150)
                        .offset(y: geometry.size.height - 150)

                    // Subtle horizontal lines for texture
                    ForEach(0..<15, id: \.self) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.02))
                            .frame(height: 1)
                            .offset(y: CGFloat(i * 60))
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 80)

                // Logo and branding section
                VStack(spacing: 12) {
                    Image("billix_logo_new")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

                    Text("Billix")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.billixLoginTeal)
                        .shadow(color: Color.white.opacity(0.8), radius: 3, x: 0, y: 0)
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                }

                Spacer()
                    .frame(height: 36)

                // Login form
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(16)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixDarkGray)
                            .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: 0)
                        Rectangle()
                            .fill(Color.gray.opacity(0.5))
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
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
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
                        .font(.system(size: 16))

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSecured.toggle()
                            }
                        }) {
                            Image(systemName: isSecured ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            // UI only
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixLoginTeal)
                    }

                    // Sign In Button
                    Button(action: {
                        handleLogin()
                    }) {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.billixLoginTeal)
                            .cornerRadius(16)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Sign up
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.billixDarkGray)
                        .shadow(color: Color.white.opacity(0.5), radius: 1, x: 0, y: 0)

                    Button("Sign up") {
                        // UI only
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixLoginTeal)
                    .shadow(color: Color.white.opacity(0.6), radius: 2, x: 0, y: 0)
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

            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isLoggedIn = true
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Wave Shape for Background Pattern

struct WaveShape: Shape {
    let phase: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2

        path.move(to: CGPoint(x: 0, y: midHeight))

        // Create smooth wave using quadratic curves
        for i in stride(from: 0, to: width, by: 40) {
            let x = i
            let relativeX = x / width
            let sine = sin((relativeX * .pi * 4) + (phase * .pi * 2))
            let y = midHeight + (sine * 20)

            path.addLine(to: CGPoint(x: x, y: y))
        }

        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()

        return path
    }
}

#Preview {
    LoginView()
}
