//
//  AuthService.swift
//  Billix
//
//  Created by Billix Team
//
//  NOTE: This is a temporary stub implementation without Supabase.
//  For production, integrate Supabase authentication.
//

import Foundation
import AuthenticationServices

/// Authentication service stub (temporary - replace with Supabase integration)
@MainActor
class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published Properties
    @Published var currentUser: UserProfile?
    @Published var isAuthenticated = false
    @Published var isLoading = false

    // MARK: - Initialization
    private init() {
        // Auto-login with mock user for development
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            self.currentUser = .preview
            self.isAuthenticated = true
        }
    }

    // MARK: - Session Management

    /// Check if there's an active session
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }

        // Mock: Always authenticated with preview user
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.currentUser = .preview
        self.isAuthenticated = true
    }

    /// Sign out current user
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: 300_000_000)
        isAuthenticated = false
        currentUser = nil
        print("✅ User signed out (mock)")
    }

    // MARK: - Email/Password Authentication

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        self.currentUser = .preview
        self.isAuthenticated = true
        print("✅ Mock sign in: \(email)")
    }

    /// Sign up with email and password
    func signUp(email: String, password: String, firstName: String, lastName: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        guard password.count >= 6 else {
            throw AuthError.passwordTooShort
        }

        try? await Task.sleep(nanoseconds: 500_000_000)

        var newUser = UserProfile.preview
        newUser.firstName = firstName
        newUser.lastName = lastName
        newUser.email = email

        self.currentUser = newUser
        self.isAuthenticated = true
        print("✅ Mock sign up: \(email)")
    }

    // MARK: - Phone Authentication

    /// Send OTP to phone number
    func sendOTP(to phoneNumber: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !phoneNumber.isEmpty else {
            throw AuthError.invalidPhoneNumber
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        print("✅ Mock OTP sent to: \(phoneNumber)")
    }

    /// Verify OTP code
    func verifyOTP(phoneNumber: String, code: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !phoneNumber.isEmpty, !code.isEmpty else {
            throw AuthError.invalidOTP
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        self.currentUser = .preview
        self.isAuthenticated = true
        print("✅ Mock OTP verified: \(phoneNumber)")
    }

    // MARK: - Apple Sign In

    /// Sign in with Apple
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: 500_000_000)
        self.currentUser = .preview
        self.isAuthenticated = true
        print("✅ Mock Apple Sign In successful")
    }

    // MARK: - Password Management

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        print("✅ Mock password reset email sent to: \(email)")
    }

    /// Update password
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard newPassword.count >= 6 else {
            throw AuthError.passwordTooShort
        }

        try? await Task.sleep(nanoseconds: 500_000_000)
        print("✅ Mock password updated")
    }

    // MARK: - Email Verification

    /// Resend verification email
    func resendVerificationEmail() async throws {
        guard let email = currentUser?.email else {
            throw AuthError.noUserLoggedIn
        }

        isLoading = true
        defer { isLoading = false }

        try? await Task.sleep(nanoseconds: 500_000_000)
        print("✅ Mock verification email resent to: \(email)")
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case invalidPhoneNumber
    case invalidOTP
    case passwordTooShort
    case signInFailed(String)
    case signUpFailed(String)
    case signOutFailed(String)
    case otpSendFailed(String)
    case otpVerificationFailed(String)
    case appleSignInFailed(String)
    case passwordResetFailed(String)
    case passwordUpdateFailed(String)
    case emailVerificationFailed(String)
    case noUserLoggedIn

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Please enter valid email and password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidOTP:
            return "Please enter a valid verification code"
        case .passwordTooShort:
            return "Password must be at least 6 characters"
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .signOutFailed(let message):
            return "Sign out failed: \(message)"
        case .otpSendFailed(let message):
            return "Failed to send code: \(message)"
        case .otpVerificationFailed(let message):
            return "Verification failed: \(message)"
        case .appleSignInFailed(let message):
            return "Apple Sign In failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .passwordUpdateFailed(let message):
            return "Password update failed: \(message)"
        case .emailVerificationFailed(let message):
            return "Email verification failed: \(message)"
        case .noUserLoggedIn:
            return "No user is currently logged in"
        }
    }
}
