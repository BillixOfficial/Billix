//
//  SetNewPasswordView.swift
//  Billix
//
//  Screen to set a new password after clicking reset link
//

import SwiftUI

struct SetNewPasswordView: View {
    @EnvironmentObject var authService: AuthService

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSecured = true
    @State private var isConfirmSecured = true
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var focusedField: Field?

    enum Field {
        case newPassword, confirmPassword
    }

    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var isValidPassword: Bool {
        newPassword.count >= 6
    }

    var body: some View {
        ZStack {
            // Sage green background matching login
            Color(hex: "#6B9B7A")
                .ignoresSafeArea()
                .onTapGesture {
                    focusedField = nil
                }

            if showSuccess {
                // Success state
                successView
            } else {
                // Password form
                formView
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            // Icon and title
            VStack(spacing: 16) {
                Image(systemName: "lock.rotation")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                Text("Set New Password")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text("Create a strong password with at least 6 characters.")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 40)

            // Form
            VStack(spacing: 16) {
                // New Password field
                ZStack(alignment: .leading) {
                    if newPassword.isEmpty {
                        Text("New Password")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .padding(.leading, 18)
                    }
                    HStack {
                        if isSecured {
                            SecureField("", text: $newPassword)
                                .focused($focusedField, equals: .newPassword)
                                .textContentType(.newPassword)
                                .font(.system(size: 17))
                                .foregroundStyle(Color(hex: "#2D3B35"))
                                .tint(Color(hex: "#3D6B4F"))
                        } else {
                            TextField("", text: $newPassword)
                                .focused($focusedField, equals: .newPassword)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            !newPassword.isEmpty && !isValidPassword ? Color.red.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
                .disabled(isLoading)

                // Password requirement hint
                if !newPassword.isEmpty && !isValidPassword {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 12))
                        Text("Password must be at least 6 characters")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                // Confirm Password field
                ZStack(alignment: .leading) {
                    if confirmPassword.isEmpty {
                        Text("Confirm Password")
                            .font(.system(size: 17))
                            .foregroundColor(Color(hex: "#9CA3AF"))
                            .padding(.leading, 18)
                    }
                    HStack {
                        if isConfirmSecured {
                            SecureField("", text: $confirmPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .textContentType(.newPassword)
                                .font(.system(size: 17))
                                .foregroundStyle(Color(hex: "#2D3B35"))
                                .tint(Color(hex: "#3D6B4F"))
                        } else {
                            TextField("", text: $confirmPassword)
                                .focused($focusedField, equals: .confirmPassword)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 17))
                                .foregroundStyle(Color(hex: "#2D3B35"))
                                .tint(Color(hex: "#3D6B4F"))
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isConfirmSecured.toggle()
                            }
                        }) {
                            Image(systemName: isConfirmSecured ? "eye.slash" : "eye")
                                .font(.system(size: 18))
                                .foregroundStyle(Color(hex: "#9CA3AF"))
                        }
                    }
                    .padding(18)
                }
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 1)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            !confirmPassword.isEmpty && !passwordsMatch ? Color.red.opacity(0.5) : Color.clear,
                            lineWidth: 2
                        )
                )
                .disabled(isLoading)

                // Passwords don't match hint
                if !confirmPassword.isEmpty && !passwordsMatch {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 12))
                        Text("Passwords don't match")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }

                // Update Password Button
                Button(action: handleUpdatePassword) {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#3D6B4F")))
                        }
                        Text("Update Password")
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
                .disabled(isLoading || !isValidPassword || !passwordsMatch)
                .opacity(isLoading || !isValidPassword || !passwordsMatch ? 0.7 : 1)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Success checkmark
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }

            Text("Password Updated!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Your password has been successfully changed. You can now sign in with your new password.")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            // Continue to Login button
            Button(action: handleContinueToLogin) {
                Text("Continue to Sign In")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "#3D6B4F"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func handleUpdatePassword() {
        guard isValidPassword && passwordsMatch else { return }

        focusedField = nil
        isLoading = true

        Task {
            do {
                try await authService.updatePassword(newPassword: newPassword)
                await MainActor.run {
                    withAnimation {
                        showSuccess = true
                    }
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }
            }
            await MainActor.run {
                isLoading = false
            }
        }
    }

    private func handleContinueToLogin() {
        // Clear the password reset state and sign out
        // This will trigger RootView to show LoginView
        authService.isResettingPassword = false
        Task {
            try? await authService.signOut()
        }
    }
}

struct SetNewPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        SetNewPasswordView()
        .environmentObject(AuthService.shared)
    }
}
