//
//  IDVerificationService.swift
//  Billix
//
//  Service for ID document verification via ID Analyzer
//

import Foundation
import UIKit
import Supabase

// MARK: - ID Verification Status

enum IDVerificationStatus: String {
    case notStarted = "not_started"
    case pending = "pending"
    case verified = "verified"
    case failed = "failed"
}

// MARK: - ID Verification Service

@MainActor
class IDVerificationService: ObservableObject {
    static let shared = IDVerificationService()

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var verificationStatus: IDVerificationStatus = .notStarted
    @Published var error: Error?
    @Published var lastErrorMessage: String?
    @Published var isIDVerified = false

    // MARK: - Private Properties

    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    private init() {}

    // MARK: - Verify ID

    /// Upload and verify an ID document
    /// - Parameters:
    ///   - frontImage: The front of the ID document
    ///   - backImage: Optional back of the ID document (for some ID types)
    /// - Returns: True if verification was successful
    func verifyID(frontImage: UIImage, backImage: UIImage? = nil) async throws -> Bool {
        isLoading = true
        verificationStatus = .pending
        error = nil
        lastErrorMessage = nil

        defer { isLoading = false }

        // Convert images to base64
        guard let frontData = frontImage.jpegData(compressionQuality: 0.8) else {
            throw IDVerificationError.imageConversionFailed
        }
        let frontBase64 = frontData.base64EncodedString()

        var backBase64: String?
        if let backImage = backImage,
           let backData = backImage.jpegData(compressionQuality: 0.8) {
            backBase64 = backData.base64EncodedString()
        }

        do {
            // Build request body
            let body = IDVerificationRequest(
                frontImage: frontBase64,
                backImage: backBase64
            )

            // Call the Edge Function
            let result: IDVerificationResponse = try await supabase.functions.invoke(
                "verify-id",
                options: FunctionInvokeOptions(body: body),
                decode: { data, _ in
                    try JSONDecoder().decode(IDVerificationResponse.self, from: data)
                }
            )

            if result.success && result.verified {
                verificationStatus = .verified
                return true
            } else {
                verificationStatus = .failed
                lastErrorMessage = result.message ?? "Verification failed"
                throw IDVerificationError.verificationFailed(result.message ?? "Unknown error")
            }

        } catch let error as IDVerificationError {
            verificationStatus = .failed
            self.error = error
            throw error
        } catch {
            verificationStatus = .failed
            let verificationError = IDVerificationError.networkError(error.localizedDescription)
            self.error = verificationError
            throw verificationError
        }
    }

    // MARK: - Check Verification Status

    /// Check if the current user has a verified ID
    func checkVerificationStatus() async throws -> IDVerificationStatus {
        guard let userId = AuthService.shared.currentUser?.id else {
            isIDVerified = false
            return .notStarted
        }

        do {
            let profiles: [IDVerificationProfile] = try await supabase
                .from("profiles")
                .select("id_verified, id_verified_at")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            if let profile = profiles.first, profile.idVerified {
                verificationStatus = .verified
                isIDVerified = true
                return .verified
            } else {
                verificationStatus = .notStarted
                isIDVerified = false
                return .notStarted
            }

        } catch {
            print("Failed to check ID verification status: \(error)")
            isIDVerified = false
            return .notStarted
        }
    }

    // MARK: - Get Full Verification Status

    /// Get combined verification status (phone + ID)
    func getVerificationTier() async throws -> VerificationTier {
        guard let userId = AuthService.shared.currentUser?.id else {
            return .basic
        }

        do {
            let profiles: [FullVerificationProfile] = try await supabase
                .from("profiles")
                .select("phone_verified, id_verified")
                .eq("user_id", value: userId.uuidString)
                .limit(1)
                .execute()
                .value

            guard let profile = profiles.first else {
                return .basic
            }

            if profile.idVerified && profile.phoneVerified {
                return .fullyVerified
            } else if profile.phoneVerified {
                return .phoneVerified
            } else {
                return .basic
            }

        } catch {
            print("Failed to get verification tier: \(error)")
            return .basic
        }
    }

    // MARK: - Reset State

    func reset() {
        verificationStatus = .notStarted
        error = nil
        lastErrorMessage = nil
    }
}

// MARK: - Verification Tiers

enum VerificationTier: String, CaseIterable {
    case basic = "basic"
    case phoneVerified = "phone_verified"
    case fullyVerified = "verified"

    var displayName: String {
        switch self {
        case .basic:
            return "Basic"
        case .phoneVerified:
            return "Phone Verified"
        case .fullyVerified:
            return "Verified"
        }
    }

    var badgeColor: String {
        switch self {
        case .basic:
            return "gray"
        case .phoneVerified:
            return "blue"
        case .fullyVerified:
            return "green"
        }
    }

    var iconName: String {
        switch self {
        case .basic:
            return "person.circle"
        case .phoneVerified:
            return "phone.badge.checkmark"
        case .fullyVerified:
            return "checkmark.seal.fill"
        }
    }
}

// MARK: - Request Types

private struct IDVerificationRequest: Encodable {
    let frontImage: String
    let backImage: String?

    enum CodingKeys: String, CodingKey {
        case frontImage = "front_image"
        case backImage = "back_image"
    }
}

// MARK: - Response Types

private struct IDVerificationResponse: Decodable {
    let success: Bool
    let verified: Bool
    let message: String?
    let documentType: String?

    enum CodingKeys: String, CodingKey {
        case success
        case verified
        case message
        case documentType = "document_type"
    }
}

private struct IDVerificationProfile: Decodable {
    let idVerified: Bool
    let idVerifiedAt: Date?

    enum CodingKeys: String, CodingKey {
        case idVerified = "id_verified"
        case idVerifiedAt = "id_verified_at"
    }
}

private struct FullVerificationProfile: Decodable {
    let phoneVerified: Bool
    let idVerified: Bool

    enum CodingKeys: String, CodingKey {
        case phoneVerified = "phone_verified"
        case idVerified = "id_verified"
    }
}

// MARK: - Errors

enum IDVerificationError: LocalizedError {
    case imageConversionFailed
    case verificationFailed(String)
    case networkError(String)
    case invalidResponse
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to process the ID image. Please try again."
        case .verificationFailed(let message):
            return message
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid server response"
        case .notAuthenticated:
            return "You must be logged in to verify your ID"
        }
    }
}
