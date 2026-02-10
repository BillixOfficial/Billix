//
//  AuthService.swift
//  Billix
//
//  Created by Billix Team
//
//  Supabase Authentication Service with Apple Sign-In support
//

import Foundation
import AuthenticationServices
import Supabase

/// Authentication service with Supabase integration
@MainActor
class AuthService: ObservableObject {

    // MARK: - Singleton
    static let shared = AuthService()

    // MARK: - Published Properties
    @Published var currentUser: CombinedUser?
    @Published var isAuthenticated = false
    @Published var needsOnboarding = false
    @Published var isLoading = true
    @Published var awaitingEmailVerification = false
    @Published var pendingVerificationEmail: String?
    @Published var isGuestMode = false
    @Published var isResettingPassword = false

    // Temporary password storage for email verification polling (cleared after verification)
    private var pendingVerificationPassword: String?

    // Temporary storage for Apple-provided name during onboarding
    var appleProvidedName: PersonNameComponents?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private var authStateTask: Task<Void, Never>?

    // MARK: - Initialization
    private init() {
        // Clear any cached session to require fresh login every time
        Task {
            try? await supabase.auth.signOut()
        }

        setupAuthStateListener()

        // Fallback: If no auth event fires within 3 seconds, set isLoading to false
        // This prevents the app from being stuck on splash screen forever
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.isLoading {
                self.isLoading = false
            }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateTask = Task { [weak self] in
            guard let self = self else { return }

            for await (event, session) in self.supabase.auth.authStateChanges {
                await MainActor.run {
                    switch event {
                    case .initialSession:
                        if let session = session {
                            Task {
                                await self.handleSession(session)
                            }
                        } else {
                            self.isLoading = false
                            self.isAuthenticated = false
                        }
                    case .signedIn:
                        if let session = session {
                            Task {
                                await self.handleSession(session)
                            }
                        }
                    case .signedOut:
                        self.currentUser = nil
                        self.isAuthenticated = false
                        self.needsOnboarding = false
                    case .tokenRefreshed:
                        break
                    case .userUpdated:
                        if let session = session {
                            Task {
                                await self.handleSession(session)
                            }
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    private func handleSession(_ session: Session) async {
        let userId = session.user.id

        do {
            // First verify the user actually exists (handles case where user was deleted but session cached)
            let userExists = await verifyUserExists(userId: userId)

            if !userExists {
                // User was deleted but session is cached - sign out
                try? await supabase.auth.signOut()
                self.currentUser = nil
                self.isAuthenticated = false
                self.needsOnboarding = false
                self.isLoading = false
                return
            }

            // Check if user has completed onboarding (has vault record)
            let vaultExists = await checkVaultExists(userId: userId)

            if vaultExists {
                // Fetch full user data
                let user = try await fetchUserData(userId: userId)
                self.currentUser = user
                self.isAuthenticated = true
                self.needsOnboarding = false

                // Update last login
                try? await updateLastLogin(userId: userId)
            } else {
                // New user needs onboarding
                self.isAuthenticated = true
                self.needsOnboarding = true
            }
        } catch {
            self.isAuthenticated = false
            self.needsOnboarding = false
        }

        self.isLoading = false
    }

    private func verifyUserExists(userId: UUID) async -> Bool {
        do {
            // Make an API call to verify the session is still valid
            // If user was deleted, this will fail with auth error
            _ = try await supabase.auth.user()
            return true
        } catch {
            return false
        }
    }

    private func checkVaultExists(userId: UUID) async -> Bool {
        do {
            let results: [UserVault] = try await supabase
                .from("user_vault")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            return !results.isEmpty
        } catch {
            return false
        }
    }

    private func fetchUserData(userId: UUID) async throws -> CombinedUser {
        async let vaultResult: UserVault = supabase
            .from("user_vault")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value

        async let profileResult: UserProfileDB = supabase
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        // Fetch from new profiles table
        let billixProfileResult: BillixProfile? = try? await supabase
            .from("profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value

        let (vault, profile) = try await (vaultResult, profileResult)

        return CombinedUser(id: userId, vault: vault, profile: profile, billixProfile: billixProfileResult)
    }

    private func updateLastLogin(userId: UUID) async throws {
        try await supabase
            .from("user_vault")
            .update(["last_login_at": ISO8601DateFormatter().string(from: Date())])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Session Management

    /// Check if there's an active session
    func checkSession() async {
        isLoading = true

        do {
            let session = try await supabase.auth.session
            await handleSession(session)
        } catch {
            isLoading = false
            isAuthenticated = false
        }
    }

    /// Sign out current user
    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        // Only attempt Supabase signout if not in guest mode
        if !isGuestMode {
            try await supabase.auth.signOut()
        }

        currentUser = nil
        isAuthenticated = false
        needsOnboarding = false
        isGuestMode = false
        appleProvidedName = nil
    }

    // MARK: - Apple Sign In

    /// Sign in with Apple credential
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed("Invalid identity token")
        }

        // Store Apple-provided name for onboarding (only available on first sign-in)
        if let fullName = credential.fullName {
            appleProvidedName = fullName
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )

            await handleSession(session)
        } catch {
            throw AuthError.appleSignInFailed(error.localizedDescription)
        }
    }

    // MARK: - Google Sign In

    /// Sign in with Google using Supabase OAuth
    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "billix://auth-callback")
            )
        } catch {
            throw AuthError.googleSignInFailed(error.localizedDescription)
        }
    }

    // MARK: - Email/Password Authentication

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            await handleSession(session)
        } catch {
            throw AuthError.signInFailed(error.localizedDescription)
        }
    }

    /// Sign up with email and password
    /// Sets awaitingEmailVerification if confirmation is required
    @discardableResult
    func signUp(email: String, password: String) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        guard password.count >= 6 else {
            throw AuthError.passwordTooShort
        }

        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )

            if let session = response.session {
                await handleSession(session)
                return false // No email confirmation needed
            } else {
                // If no session returned, attempt automatic sign-in
                // (works when email confirmation is disabled in Supabase)
                do {
                    let signInSession = try await supabase.auth.signIn(
                        email: email,
                        password: password
                    )
                    await handleSession(signInSession)
                    return false
                } catch {
                    // Email confirmation truly required - show verification screen
                    self.pendingVerificationEmail = email
                    self.pendingVerificationPassword = password
                    self.awaitingEmailVerification = true
                    return true
                }
            }
        } catch {
            throw AuthError.signUpFailed(error.localizedDescription)
        }
    }

    /// Sign in as guest - allows app exploration without authentication
    func signInAsGuest() async throws {
        isLoading = true

        // Set guest mode flags to bypass authentication and onboarding
        self.isGuestMode = true
        self.isAuthenticated = true
        self.needsOnboarding = false
        self.currentUser = nil

        // Small delay for smooth transition
        try? await Task.sleep(nanoseconds: 300_000_000)

        self.isLoading = false
    }

    // MARK: - Email Verification

    /// Check if user has verified their email (called by polling)
    func checkEmailVerification() async -> Bool {
        guard let email = pendingVerificationEmail,
              let password = pendingVerificationPassword else { return false }

        do {
            // Try to sign in - if email is verified, this will succeed
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            // Success! User is verified and signed in
            await handleSession(session)
            awaitingEmailVerification = false
            pendingVerificationEmail = nil
            pendingVerificationPassword = nil
            return true
        } catch {
            // Sign-in failed - email likely not verified yet
            // Check if the error message indicates unverified email
            let errorMessage = error.localizedDescription.lowercased()
            if errorMessage.contains("confirm") || errorMessage.contains("verify") {
                // Still waiting for email confirmation
                return false
            }
            // Some other error - still return false
            return false
        }
    }

    /// Resend verification email
    func resendVerificationEmail(email: String) async throws {
        do {
            try await supabase.auth.resend(
                email: email,
                type: .signup
            )
        } catch {
            throw AuthError.emailVerificationFailed(error.localizedDescription)
        }
    }

    /// Cancel email verification and go back to login
    func cancelEmailVerification() {
        awaitingEmailVerification = false
        pendingVerificationEmail = nil
        pendingVerificationPassword = nil
    }

    // MARK: - Onboarding Completion

    /// Complete onboarding by creating profile record in the new profiles table
    func completeOnboarding(
        zipCode: String,
        handle: String,
        displayName: String,
        avatarData: Data? = nil,
        birthday: Date,
        gender: String? = nil,
        goal: String? = nil
    ) async throws {
        isLoading = true
        // NOTE: Removed defer - set isLoading explicitly at the end to ensure
        // SwiftUI processes needsOnboarding change before loading state changes

        guard let session = try? await supabase.auth.session else {
            isLoading = false
            throw AuthError.noUserLoggedIn
        }

        let userId = session.user.id

        // Format birthday as ISO date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let birthdayString = dateFormatter.string(from: birthday)

        do {
            // Look up city/state from zip code
            let zipInfo = await ZipCodeService.shared.lookupZipCode(zipCode)

            // Create profile record in the new profiles table
            var profileData: [String: AnyJSON] = [
                "user_id": .string(userId.uuidString),
                "handle": .string(handle),
                "display_name": .string(displayName),
                "zip_code": .string(zipCode),
                "birthday": .string(birthdayString),
                "trust_score": .integer(0),
                "is_trusted_helper": .bool(false),
                "bills_analyzed_count": .integer(0),
                "badge_level": .string("newbie"),
                "subscription_tier": .string("free"),
                "profile_visibility": .string("public")
            ]

            // Add city and state if zip lookup succeeded
            if let zipInfo = zipInfo {
                profileData["city"] = .string(zipInfo.city)
                profileData["state"] = .string(zipInfo.state)
            }

            // Add optional gender if provided
            if let gender = gender {
                profileData["gender"] = .string(gender)
            }

            try await supabase
                .from("profiles")
                .insert(profileData)
                .execute()

            // Create user vault record for legacy compatibility
            let vaultInsert = UserVaultInsert(
                id: userId,
                zipCode: zipCode,
                state: nil,
                marketplaceOptOut: false
            )

            try await supabase
                .from("user_vault")
                .insert(vaultInsert)
                .execute()

            // Fetch the created user data
            let user = try await fetchUserData(userId: userId)

            // Force SwiftUI to prepare for state change
            self.objectWillChange.send()

            // Update all state - set isLoading LAST to ensure view updates properly
            self.currentUser = user
            self.needsOnboarding = false
            self.appleProvidedName = nil
            self.isLoading = false
        } catch {
            isLoading = false
            throw error
        }
    }

    private func uploadAvatar(userId: UUID, imageData: Data) async throws -> String {
        // Use unique filename with timestamp to bypass image caching
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "\(userId.uuidString)/avatar_\(timestamp).jpg"

        print("[Avatar] Uploading to path: \(path)")
        print("[Avatar] Image data size: \(imageData.count) bytes")

        try await supabase.storage
            .from("avatars")
            .upload(
                path,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )

        let publicURL = try supabase.storage
            .from("avatars")
            .getPublicURL(path: path)

        print("[Avatar] Upload complete. Public URL: \(publicURL.absoluteString)")

        return publicURL.absoluteString
    }

    // MARK: - Password Management

    /// Send password reset email
    func resetPassword(email: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw AuthError.passwordResetFailed(error.localizedDescription)
        }
    }

    /// Update password
    func updatePassword(newPassword: String) async throws {
        isLoading = true
        defer { isLoading = false }

        guard newPassword.count >= 6 else {
            throw AuthError.passwordTooShort
        }

        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
        } catch {
            throw AuthError.passwordUpdateFailed(error.localizedDescription)
        }
    }

    // MARK: - Handle Availability

    /// Check if a handle is already taken
    func isHandleAvailable(_ handle: String) async -> Bool {
        let normalizedHandle = handle.trimmingCharacters(in: .whitespaces).lowercased()

        guard !normalizedHandle.isEmpty else { return false }

        do {
            let results: [[String: String]] = try await supabase
                .from("profiles")
                .select("handle")
                .eq("handle", value: normalizedHandle)
                .execute()
                .value

            return results.isEmpty
        } catch {
            // On error, assume it's available to let server-side validation handle it
            return true
        }
    }

    // MARK: - Profile Updates

    /// Update user profile (updates both legacy and new profiles tables)
    func updateProfile(displayName: String? = nil, bio: String? = nil, goal: String? = nil) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.noUserLoggedIn
        }

        // Update profiles table (consolidated from user_profiles)
        var profileUpdates: [String: String] = [:]
        if let displayName = displayName { profileUpdates["display_name"] = displayName }
        if let bio = bio { profileUpdates["bio"] = bio }
        if let goal = goal { profileUpdates["goal"] = goal }

        if !profileUpdates.isEmpty {
            try await supabase
                .from("profiles")
                .update(profileUpdates)
                .eq("user_id", value: userId.uuidString)
                .execute()
        }

        // Refresh user data
        let user = try await fetchUserData(userId: userId)
        self.currentUser = user
    }

    /// Update bio only
    func updateBio(_ bio: String) async throws {
        try await updateProfile(bio: bio)
    }

    /// Update handle/username
    func updateHandle(_ handle: String) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.noUserLoggedIn
        }

        try await supabase
            .from("profiles")
            .update(["handle": handle])
            .eq("user_id", value: userId.uuidString)
            .execute()

        // Refresh user data
        let user = try await fetchUserData(userId: userId)
        self.currentUser = user
    }

    /// Update avatar
    func updateAvatar(imageData: Data) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.noUserLoggedIn
        }

        print("[Avatar] Starting avatar update for user: \(userId)")

        let avatarUrl = try await uploadAvatar(userId: userId, imageData: imageData)

        print("[Avatar] Updating database with new URL: \(avatarUrl)")

        try await supabase
            .from("profiles")
            .update(["avatar_url": avatarUrl])
            .eq("user_id", value: userId.uuidString)
            .execute()

        print("[Avatar] Database updated. Refreshing user data...")

        // Refresh user data
        let user = try await fetchUserData(userId: userId)
        self.currentUser = user

        print("[Avatar] User data refreshed. New avatar URL in profile: \(user.profile.avatarUrl ?? "nil")")
    }

    /// Refresh user data from database
    /// Call this after updating user profile fields to reflect changes in the UI
    func refreshUserData() async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.noUserLoggedIn
        }

        let user = try await fetchUserData(userId: userId)
        self.currentUser = user
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
    case googleSignInFailed(String)
    case passwordResetFailed(String)
    case passwordUpdateFailed(String)
    case emailVerificationFailed(String)
    case noUserLoggedIn
    case onboardingFailed(String)

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
        case .googleSignInFailed(let message):
            return "Google Sign In failed: \(message)"
        case .passwordResetFailed(let message):
            return "Password reset failed: \(message)"
        case .passwordUpdateFailed(let message):
            return "Password update failed: \(message)"
        case .emailVerificationFailed(let message):
            return "Email verification failed: \(message)"
        case .noUserLoggedIn:
            return "No user is currently logged in"
        case .onboardingFailed(let message):
            return "Onboarding failed: \(message)"
        }
    }
}
