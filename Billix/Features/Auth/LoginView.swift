import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isGoogleLoading = false
    @State private var showEnrollmentSheet = false
    @State private var showForgotPassword = false
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            // Lighter sage green background
            Color(hex: "#6B9B7A")
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                    focusedField = nil
                }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 50)

                // Logo and branding section
                VStack(spacing: 12) {
                    Image("billix_logo_new")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 160, height: 160)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)

                    Text("Billix")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
                }

                Spacer()
                    .frame(height: 36)

                // Login form - Sign In ONLY
                VStack(spacing: 16) {
                    // Apple Sign In
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 56)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .disabled(isLoading || isGoogleLoading)

                    // Google Sign In
                    GoogleSignInButton(
                        isLoading: isGoogleLoading,
                        action: handleGoogleSignIn
                    )
                    .disabled(isLoading || isGoogleLoading)

                    // Divider
                    HStack(spacing: 12) {
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(height: 1)
                        Text("or")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 6)

                    // Email
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.leading, 18)
                        }
                        TextField("", text: $email)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .font(.system(size: 17))
                            .foregroundStyle(Color(hex: "#2D3B35"))
                            .tint(Color(hex: "#3D6B4F"))
                            .padding(18)
                    }
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                    .disabled(isLoading)

                    // Password
                    ZStack(alignment: .leading) {
                        if password.isEmpty {
                            Text("Password")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.leading, 18)
                        }
                        HStack {
                            if isSecured {
                                SecureField("", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .textContentType(.password)
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color(hex: "#2D3B35"))
                                    .tint(Color(hex: "#3D6B4F"))
                            } else {
                                TextField("", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .textContentType(.password)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 17))
                                    .foregroundStyle(Color(hex: "#2D3B35"))
                                    .tint(Color(hex: "#3D6B4F"))
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isSecured.toggle()
                                }
                            }) {
                                Image(systemName: isSecured ? "eye.slash" : "eye")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color(hex: "#9CA3AF"))
                            }
                        }
                        .padding(18)
                    }
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                    .disabled(isLoading)

                    // Sign In Button - white with dark green text
                    Button(action: handleLogin) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#3D6B4F")))
                            }
                            Text("Sign In")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#3D6B4F"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.7 : 1)

                    // Forgot Password - below sign in
                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
                    .disabled(isLoading)
                }
                .padding(.horizontal, 28)

                Spacer()

                // Bottom quick links
                LoginQuickLinks(onEnroll: {
                    showEnrollmentSheet = true
                })
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showEnrollmentSheet) {
            EnrollmentMethodView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
                .environmentObject(authService)
        }
    }

    // MARK: - Actions

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showErrorMessage("Invalid Apple credential")
                return
            }

            isLoading = true

            Task {
                do {
                    try await authService.signInWithApple(credential: credential)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } catch {
                    showErrorMessage(error.localizedDescription)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
                isLoading = false
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    private func handleLogin() {
        hideKeyboard()
        focusedField = nil

        guard !email.isEmpty, !password.isEmpty else {
            showErrorMessage("Please enter email and password")
            return
        }

        isLoading = true

        Task {
            do {
                try await authService.signIn(email: email, password: password)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                showErrorMessage(error.localizedDescription)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            isLoading = false
        }
    }

    private func handleForgotPassword() {
        guard !email.isEmpty else {
            showErrorMessage("Please enter your email address")
            return
        }

        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email)
                showErrorMessage("Password reset email sent. Check your inbox.")
            } catch {
                showErrorMessage(error.localizedDescription)
            }
            isLoading = false
        }
    }

    private func handleGoogleSignIn() {
        hideKeyboard()
        focusedField = nil
        isGoogleLoading = true

        Task {
            do {
                try await authService.signInWithGoogle()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            } catch {
                showErrorMessage(error.localizedDescription)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            isGoogleLoading = false
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Google Sign In Button with Google Colors

struct GoogleSignInButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#5A6B64")))
                } else {
                    GoogleColoredG()
                        .frame(width: 18, height: 18)
                }
                Text("Sign in with Google")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(Color(hex: "#1F1F1F"))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(14)
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Google Colored G Logo

struct GoogleColoredG: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2
            let lineWidth: CGFloat = 4

            // Colors
            let blue = Color(hex: "#4285F4")
            let green = Color(hex: "#34A853")
            let yellow = Color(hex: "#FBBC05")
            let red = Color(hex: "#EA4335")

            // Draw the G shape using arcs
            // Red arc (top-left, from ~135° to ~225°)
            var redPath = Path()
            redPath.addArc(center: center, radius: radius, startAngle: .degrees(135), endAngle: .degrees(225), clockwise: false)
            context.stroke(redPath, with: .color(red), lineWidth: lineWidth)

            // Yellow arc (bottom-left, from ~225° to ~270°)
            var yellowPath = Path()
            yellowPath.addArc(center: center, radius: radius, startAngle: .degrees(225), endAngle: .degrees(280), clockwise: false)
            context.stroke(yellowPath, with: .color(yellow), lineWidth: lineWidth)

            // Green arc (bottom, from ~270° to ~360°)
            var greenPath = Path()
            greenPath.addArc(center: center, radius: radius, startAngle: .degrees(280), endAngle: .degrees(360), clockwise: false)
            context.stroke(greenPath, with: .color(green), lineWidth: lineWidth)

            // Blue arc (right side, from 0° to ~135°) - this creates the G opening
            var bluePath = Path()
            bluePath.addArc(center: center, radius: radius, startAngle: .degrees(0), endAngle: .degrees(135), clockwise: false)
            context.stroke(bluePath, with: .color(blue), lineWidth: lineWidth)

            // Blue horizontal bar (the G's crossbar)
            let barRect = CGRect(
                x: center.x - 1,
                y: center.y - lineWidth / 2,
                width: radius + 2,
                height: lineWidth
            )
            context.fill(Path(barRect), with: .color(blue))
        }
    }
}

// MARK: - Bottom Quick Links

struct LoginQuickLinks: View {
    let onEnroll: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                QuickLinkButton(icon: "person.circle", label: "ENROLL", action: onEnroll)
                QuickLinkButton(icon: "questionmark.circle", label: "HELP", action: openHelp)
                QuickLinkButton(icon: "lock.shield", label: "SECURITY", action: openSecurity)
                QuickLinkButton(icon: "globe", label: "BILLIX.COM", action: openWebsite)
            }

            Text("App Version 1.0.0")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 24)
        .background(Color(hex: "#5A8A69"))
    }

    private func openHelp() {
        if let url = URL(string: "https://billixapp.com/help") {
            UIApplication.shared.open(url)
        }
    }

    private func openSecurity() {
        if let url = URL(string: "https://billixapp.com/security") {
            UIApplication.shared.open(url)
        }
    }

    private func openWebsite() {
        if let url = URL(string: "https://billixapp.com") {
            UIApplication.shared.open(url)
        }
    }
}

struct QuickLinkButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Enrollment Method View (Sign Up Options)

struct EnrollmentMethodView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var showEmailSignUp = false
    @State private var isGoogleLoading = false
    @State private var isAppleLoading = false
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#6B9B7A")
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Create Your Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Choose how you'd like to sign up")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Spacer()
                        .frame(height: 20)

                    // Sign up options
                    VStack(spacing: 16) {
                        // Sign up with Apple
                        SignInWithAppleButton(.signUp) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignUp(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 56)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .disabled(isAppleLoading || isGoogleLoading)

                        // Sign up with Google
                        Button(action: handleGoogleSignUp) {
                            HStack(spacing: 10) {
                                if isGoogleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#5A6B64")))
                                } else {
                                    GoogleColoredG()
                                        .frame(width: 18, height: 18)
                                }
                                Text("Sign up with Google")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(Color(hex: "#1F1F1F"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .disabled(isAppleLoading || isGoogleLoading)

                        // Sign up with Email
                        Button(action: { showEmailSignUp = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "#3D6B4F"))
                                Text("Sign up with Email")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundColor(Color(hex: "#3D6B4F"))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(14)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .disabled(isAppleLoading || isGoogleLoading)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .sheet(isPresented: $showEmailSignUp) {
            EmailSignUpView()
                .environmentObject(authService)
        }
    }

    private func handleAppleSignUp(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showErrorMessage("Invalid Apple credential")
                return
            }

            isAppleLoading = true

            Task {
                do {
                    try await authService.signInWithApple(credential: credential)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    dismiss()
                } catch {
                    showErrorMessage(error.localizedDescription)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
                isAppleLoading = false
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                showErrorMessage(error.localizedDescription)
            }
        }
    }

    private func handleGoogleSignUp() {
        isGoogleLoading = true

        Task {
            do {
                try await authService.signInWithGoogle()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            } catch {
                showErrorMessage(error.localizedDescription)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            isGoogleLoading = false
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Email Sign Up View

struct EmailSignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSecured = true
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var focusedField: EmailSignUpField?

    enum EmailSignUpField {
        case email, password, confirmPassword
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#6B9B7A")
                    .ignoresSafeArea()
                    .onTapGesture {
                        focusedField = nil
                    }

                VStack(spacing: 24) {
                    Spacer()
                        .frame(height: 40)

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Sign Up with Email")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()
                        .frame(height: 20)

                    // Form
                    VStack(spacing: 16) {
                        // Email
                        ZStack(alignment: .leading) {
                            if email.isEmpty {
                                Text("Email")
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                    .padding(.leading, 18)
                            }
                            TextField("", text: $email)
                                .focused($focusedField, equals: .email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 17))
                                .foregroundStyle(Color(hex: "#2D3B35"))
                                .tint(Color(hex: "#3D6B4F"))
                                .padding(18)
                        }
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)

                        // Password
                        ZStack(alignment: .leading) {
                            if password.isEmpty {
                                Text("Password")
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                    .padding(.leading, 18)
                            }
                            HStack {
                                if isSecured {
                                    SecureField("", text: $password)
                                        .focused($focusedField, equals: .password)
                                        .textContentType(.newPassword)
                                        .font(.system(size: 17))
                                        .foregroundStyle(Color(hex: "#2D3B35"))
                                        .tint(Color(hex: "#3D6B4F"))
                                } else {
                                    TextField("", text: $password)
                                        .focused($focusedField, equals: .password)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .font(.system(size: 17))
                                        .foregroundStyle(Color(hex: "#2D3B35"))
                                        .tint(Color(hex: "#3D6B4F"))
                                }

                                Button(action: { isSecured.toggle() }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color(hex: "#9CA3AF"))
                                }
                            }
                            .padding(18)
                        }
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)

                        // Confirm Password
                        ZStack(alignment: .leading) {
                            if confirmPassword.isEmpty {
                                Text("Confirm Password")
                                    .font(.system(size: 17))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                                    .padding(.leading, 18)
                            }
                            HStack {
                                if isSecured {
                                    SecureField("", text: $confirmPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .textContentType(.newPassword)
                                        .font(.system(size: 17))
                                        .foregroundStyle(Color(hex: "#2D3B35"))
                                        .tint(Color(hex: "#3D6B4F"))
                                } else {
                                    TextField("", text: $confirmPassword)
                                        .focused($focusedField, equals: .confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .font(.system(size: 17))
                                        .foregroundStyle(Color(hex: "#2D3B35"))
                                        .tint(Color(hex: "#3D6B4F"))
                                }
                            }
                            .padding(18)
                        }
                        .background(Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)

                        // Create Account Button
                        Button(action: handleSignUp) {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#3D6B4F")))
                                }
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#3D6B4F"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 8)
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.7 : 1)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
    }

    private func handleSignUp() {
        focusedField = nil

        guard !email.isEmpty else {
            showErrorMessage("Please enter your email")
            return
        }

        guard email.contains("@") && email.contains(".") else {
            showErrorMessage("Please enter a valid email address")
            return
        }

        guard !password.isEmpty else {
            showErrorMessage("Please enter a password")
            return
        }

        guard password.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters")
            return
        }

        guard password == confirmPassword else {
            showErrorMessage("Passwords do not match")
            return
        }

        isLoading = true

        Task {
            do {
                _ = try await authService.signUp(email: email, password: password)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            } catch {
                showErrorMessage(error.localizedDescription)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            isLoading = false
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService.shared)
}
