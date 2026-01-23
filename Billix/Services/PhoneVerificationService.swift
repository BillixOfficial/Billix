//
//  PhoneVerificationService.swift
//  Billix
//
//  Service for phone number verification via Twilio
//

import Foundation
import Supabase

// MARK: - Phone Verification Service

@MainActor
class PhoneVerificationService: ObservableObject {
    static let shared = PhoneVerificationService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var isSendingCode = false
    @Published var isVerifying = false
    @Published var error: Error?
    @Published var codeSent = false
    @Published var isPhoneVerified = false

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Send Verification Code

    /// Send a verification code to the specified phone number
    func sendVerificationCode(to phoneNumber: String) async throws {
        isSendingCode = true
        error = nil
        codeSent = false

        defer { isSendingCode = false }

        // Validate phone number format
        let cleanedNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        guard cleanedNumber.count >= 10 else {
            throw PhoneVerificationError.invalidPhoneNumber
        }

        do {
            // Call the Edge Function
            let result: SendCodeResponse = try await supabase.functions.invoke(
                "verify-phone",
                options: FunctionInvokeOptions(
                    body: [
                        "action": "send",
                        "phone_number": cleanedNumber
                    ]
                ),
                decode: { data, _ in
                    try JSONDecoder().decode(SendCodeResponse.self, from: data)
                }
            )

            if result.success {
                codeSent = true
            } else {
                throw PhoneVerificationError.sendFailed(result.error ?? "Unknown error")
            }

        } catch let error as PhoneVerificationError {
            self.error = error
            throw error
        } catch {
            let verificationError = PhoneVerificationError.networkError(error.localizedDescription)
            self.error = verificationError
            throw verificationError
        }
    }

    // MARK: - Verify Code

    /// Verify the code entered by the user
    func verifyCode(_ code: String, for phoneNumber: String) async throws -> Bool {
        isVerifying = true
        error = nil

        defer { isVerifying = false }

        // Validate code format
        let cleanedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanedCode.count >= 4 else {
            throw PhoneVerificationError.invalidCode
        }

        let cleanedNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

        do {
            // Call the Edge Function
            let result: VerifyCodeResponse = try await supabase.functions.invoke(
                "verify-phone",
                options: FunctionInvokeOptions(
                    body: [
                        "action": "verify",
                        "phone_number": cleanedNumber,
                        "code": cleanedCode
                    ]
                ),
                decode: { data, _ in
                    try JSONDecoder().decode(VerifyCodeResponse.self, from: data)
                }
            )

            if result.success && result.verified {
                return true
            } else {
                throw PhoneVerificationError.verificationFailed(result.message ?? "Invalid code")
            }

        } catch let error as PhoneVerificationError {
            self.error = error
            throw error
        } catch {
            let verificationError = PhoneVerificationError.networkError(error.localizedDescription)
            self.error = verificationError
            throw verificationError
        }
    }

    // MARK: - Check Verification Status

    /// Check if the current user has a verified phone number
    func checkVerificationStatus() async throws -> Bool {
        guard let userId = AuthService.shared.currentUser?.id else {
            isPhoneVerified = false
            return false
        }

        do {
            let profiles: [PhoneVerificationProfile] = try await supabase
                .from("profiles")
                .select("phone_verified")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            let verified = profiles.first?.phoneVerified ?? false
            isPhoneVerified = verified
            return verified

        } catch {
            print("Failed to check phone verification status: \(error)")
            isPhoneVerified = false
            return false
        }
    }

    // MARK: - Reset State

    func reset() {
        codeSent = false
        error = nil
    }
}

// MARK: - Response Types

private struct SendCodeResponse: Decodable {
    let success: Bool
    let message: String?
    let error: String?
}

private struct VerifyCodeResponse: Decodable {
    let success: Bool
    let verified: Bool
    let message: String?
}

private struct PhoneVerificationProfile: Decodable {
    let phoneVerified: Bool

    enum CodingKeys: String, CodingKey {
        case phoneVerified = "phone_verified"
    }
}

// MARK: - Errors

enum PhoneVerificationError: LocalizedError {
    case invalidPhoneNumber
    case invalidCode
    case sendFailed(String)
    case verificationFailed(String)
    case networkError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .invalidCode:
            return "Please enter the verification code"
        case .sendFailed(let message):
            return "Failed to send code: \(message)"
        case .verificationFailed(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}
