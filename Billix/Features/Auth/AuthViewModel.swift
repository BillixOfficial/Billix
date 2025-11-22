//
//  AuthViewModel.swift
//  Billix
//
//  Created by Billix Team
//

import Foundation
import SwiftUI
import AuthenticationServices

/// ViewModel for managing authentication state and flows
@MainActor
class AuthViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // Form states
    @Published var email = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var phoneNumber = ""
    @Published var otpCode = ""

    // View states
    @Published var isSignUpMode = false
    @Published var isPhoneAuthMode = false
    @Published var isOTPSent = false
    @Published var isPasswordResetMode = false

    // MARK: - Private Properties
    private let authService = AuthService.shared

    // MARK: - Initialization
    init() {
        // Observe auth service changes
        Task {
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                if authService.isAuthenticated != isAuthenticated {
                    isAuthenticated = authService.isAuthenticated
                    currentUser = authService.currentUser
                }

                if authService.isLoading != isLoading {
                    isLoading = authService.isLoading
                }
            }
        }

        // Check for existing session
        Task {
            await checkSession()
        }
    }

    // MARK: - Authentication Actions

    /// Check for existing session
    func checkSession() async {
        await authService.checkSession()
    }

    /// Sign in with email/password
    func signIn() async {
        guard validateEmailPassword() else { return }

        do {
            try await authService.signIn(email: email, password: password)
            clearForm()
        } catch {
            handleError(error)
        }
    }

    /// Sign up with email/password
    func signUp() async {
        guard validateSignUp() else { return }

        do {
            try await authService.signUp(
                email: email,
                password: password,
                firstName: firstName,
                lastName: lastName
            )
            clearForm()
        } catch {
            handleError(error)
        }
    }

    /// Sign out
    func signOut() async {
        do {
            try await authService.signOut()
            clearForm()
        } catch {
            handleError(error)
        }
    }

    /// Send OTP to phone
    func sendOTP() async {
        guard validatePhoneNumber() else { return }

        do {
            try await authService.sendOTP(to: phoneNumber)
            isOTPSent = true
        } catch {
            handleError(error)
        }
    }

    /// Verify OTP code
    func verifyOTP() async {
        guard !otpCode.isEmpty else {
            showErrorMessage("Please enter the verification code")
            return
        }

        do {
            try await authService.verifyOTP(phoneNumber: phoneNumber, code: otpCode)
            clearForm()
        } catch {
            handleError(error)
        }
    }

    /// Sign in with Apple
    func signInWithApple(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                showErrorMessage("Invalid Apple credential")
                return
            }

            do {
                try await authService.signInWithApple(credential: credential)
            } catch {
                handleError(error)
            }

        case .failure(let error):
            handleError(error)
        }
    }

    /// Send password reset email
    func resetPassword() async {
        guard validateEmail() else { return }

        do {
            try await authService.resetPassword(email: email)
            showSuccessMessage("Password reset email sent! Check your inbox.")
            isPasswordResetMode = false
        } catch {
            handleError(error)
        }
    }

    /// Resend email verification
    func resendVerificationEmail() async {
        do {
            try await authService.resendVerificationEmail()
            showSuccessMessage("Verification email sent!")
        } catch {
            handleError(error)
        }
    }

    // MARK: - Validation

    private func validateEmail() -> Bool {
        guard !email.isEmpty else {
            showErrorMessage("Please enter your email")
            return false
        }

        guard email.contains("@") && email.contains(".") else {
            showErrorMessage("Please enter a valid email address")
            return false
        }

        return true
    }

    private func validateEmailPassword() -> Bool {
        guard validateEmail() else { return false }

        guard !password.isEmpty else {
            showErrorMessage("Please enter your password")
            return false
        }

        return true
    }

    private func validateSignUp() -> Bool {
        guard !firstName.isEmpty else {
            showErrorMessage("Please enter your first name")
            return false
        }

        guard !lastName.isEmpty else {
            showErrorMessage("Please enter your last name")
            return false
        }

        guard validateEmail() else { return false }

        guard password.count >= 6 else {
            showErrorMessage("Password must be at least 6 characters")
            return false
        }

        return true
    }

    private func validatePhoneNumber() -> Bool {
        guard !phoneNumber.isEmpty else {
            showErrorMessage("Please enter your phone number")
            return false
        }

        // Basic phone validation (US format)
        let cleanedPhone = phoneNumber.filter { $0.isNumber }
        guard cleanedPhone.count == 10 || cleanedPhone.count == 11 else {
            showErrorMessage("Please enter a valid phone number")
            return false
        }

        return true
    }

    // MARK: - UI Actions

    /// Toggle between sign in and sign up modes
    func toggleMode() {
        isSignUpMode.toggle()
        clearError()
    }

    /// Toggle phone auth mode
    func togglePhoneAuth() {
        isPhoneAuthMode.toggle()
        isOTPSent = false
        clearError()
    }

    /// Toggle password reset mode
    func togglePasswordReset() {
        isPasswordResetMode.toggle()
        clearError()
    }

    /// Clear form fields
    func clearForm() {
        email = ""
        password = ""
        firstName = ""
        lastName = ""
        phoneNumber = ""
        otpCode = ""
        isOTPSent = false
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        if let authError = error as? AuthError {
            showErrorMessage(authError.localizedDescription)
        } else {
            showErrorMessage(error.localizedDescription)
        }
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            clearError()
        }
    }

    private func showSuccessMessage(_ message: String) {
        errorMessage = message
        showError = true

        // Auto-dismiss after 2 seconds
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            clearError()
        }
    }

    private func clearError() {
        errorMessage = nil
        showError = false
    }
}
