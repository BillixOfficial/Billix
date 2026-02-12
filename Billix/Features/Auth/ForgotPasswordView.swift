//
//  ForgotPasswordView.swift
//  Billix
//
//  Password reset request screen
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    @State private var showError = false
    @FocusState private var isEmailFocused: Bool

    var body: some View {
        ZStack {
            // Sage green background matching login
            Color(hex: "#6B9B7A")
                .ignoresSafeArea()
                .onTapGesture {
                    isEmailFocused = false
                }

            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Spacer()
                    .frame(height: 40)

                // Icon and title
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 60))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

                    Text("Reset Password")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()
                    .frame(height: 40)

                // Form
                VStack(spacing: 16) {
                    // Email field
                    ZStack(alignment: .leading) {
                        if email.isEmpty {
                            Text("Email")
                                .font(.system(size: 17))
                                .foregroundColor(Color(hex: "#9CA3AF"))
                                .padding(.leading, 18)
                        }
                        TextField("", text: $email)
                            .focused($isEmailFocused)
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
                    .disabled(isLoading || showSuccess)

                    // Send Reset Link Button
                    Button(action: handleResetPassword) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#3D6B4F")))
                            }
                            Text(showSuccess ? "Email Sent!" : "Send Reset Link")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(showSuccess ? .white : Color(hex: "#3D6B4F"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(showSuccess ? Color(hex: "#5B8A6B") : Color.white)
                        .cornerRadius(14)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(isLoading || showSuccess || email.isEmpty)
                    .opacity((isLoading || email.isEmpty) && !showSuccess ? 0.7 : 1)

                    if showSuccess {
                        VStack(spacing: 8) {
                            Text("Check your inbox")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)

                            Text("We sent a password reset link to \(email)")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Back to login link
                Button(action: { dismiss() }) {
                    Text("Back to Sign In")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.bottom, 40)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An error occurred")
        }
        .animation(.easeInOut(duration: 0.3), value: showSuccess)
    }

    // MARK: - Actions

    private func handleResetPassword() {
        guard !email.isEmpty else { return }

        isEmailFocused = false
        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    withAnimation {
                        showSuccess = true
                    }
                    // Haptic feedback
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
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
        .environmentObject(AuthService.shared)
    }
}
