//
//  ScreenshotVerificationService.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Service for verifying payment screenshots using Vision OCR
//

import Foundation
import Vision
import UIKit
import Supabase

// Note: ScreenshotVerificationStatus is defined in TrustLadderEnums.swift

// MARK: - Verification Errors

enum VerificationError: LocalizedError {
    case imageLoadFailed
    case ocrFailed
    case noTextFound
    case amountNotFound
    case providerNotFound
    case uploadFailed

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "Failed to load the image"
        case .ocrFailed:
            return "Failed to read text from image"
        case .noTextFound:
            return "No text found in the screenshot"
        case .amountNotFound:
            return "Could not find the payment amount"
        case .providerNotFound:
            return "Could not identify the provider"
        case .uploadFailed:
            return "Failed to upload screenshot"
        }
    }
}

// MARK: - Screenshot Verification Service

@MainActor
class ScreenshotVerificationService: ObservableObject {

    // MARK: - Singleton
    static let shared = ScreenshotVerificationService()

    // MARK: - Published Properties
    @Published var isProcessing = false
    @Published var lastResult: ScreenshotVerificationResult?
    @Published var error: VerificationError?

    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }

    // Known provider patterns for OCR matching
    private let providerPatterns: [String: [String]] = [
        // Streaming (Tier 1)
        "netflix": ["netflix", "nflx"],
        "spotify": ["spotify"],
        "disney_plus": ["disney+", "disney plus", "disneyplus"],
        "xbox_game_pass": ["xbox", "game pass", "gamepass", "microsoft"],
        "gym": ["planet fitness", "la fitness", "gym", "fitness", "anytime fitness", "24 hour"],

        // Utilities (Tier 2)
        "water": ["water", "utility", "municipal"],
        "electric": ["electric", "power", "energy", "edison", "pge", "duke energy"],
        "gas": ["gas", "natural gas", "piedmont", "centerpoint"],
        "internet": ["internet", "wifi", "comcast", "xfinity", "spectrum", "att", "at&t", "verizon fios"],

        // Guardian (Tier 3)
        "car_insurance": ["insurance", "geico", "progressive", "state farm", "allstate", "auto"],
        "phone_plan": ["t-mobile", "verizon", "at&t", "sprint", "mint mobile", "wireless"],
        "medical": ["medical", "health", "hospital", "clinic", "doctor", "copay"]
    ]

    // MARK: - Initialization
    private init() {}

    // MARK: - Main Verification Method

    /// Verifies a payment screenshot and returns the verification result
    func verifyScreenshot(
        image: UIImage,
        expectedAmount: Double,
        expectedProvider: String,
        swapId: UUID
    ) async throws -> ScreenshotVerificationResult {
        isProcessing = true
        error = nil
        defer { isProcessing = false }

        // 1. Perform OCR
        let rawText = try await performOCR(on: image)

        guard !rawText.isEmpty else {
            throw VerificationError.noTextFound
        }

        // 2. Extract amount from text
        let extractedAmount = extractAmount(from: rawText)

        // 3. Extract provider from text
        let extractedProvider = extractProvider(from: rawText, expected: expectedProvider)

        // 4. Extract date if present
        let extractedDate = extractDate(from: rawText)

        // 5. Calculate confidence and determine status
        let (confidence, flags) = calculateConfidence(
            rawText: rawText,
            extractedAmount: extractedAmount,
            extractedProvider: extractedProvider,
            extractedDate: extractedDate,
            expectedAmount: expectedAmount,
            expectedProvider: expectedProvider
        )

        let status = determineStatus(confidence: confidence, flags: flags)

        // 6. Upload screenshot to storage
        _ = try await uploadScreenshot(image: image, swapId: swapId)

        // 7. Create result
        let result = ScreenshotVerificationResult(
            rawText: rawText,
            extractedAmount: extractedAmount,
            extractedProvider: extractedProvider,
            extractedDate: extractedDate,
            confidence: confidence,
            status: status,
            flags: flags
        )

        self.lastResult = result
        return result
    }

    // MARK: - OCR Methods

    /// Performs OCR on the image using Vision framework
    private func performOCR(on image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw VerificationError.imageLoadFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if error != nil {
                    continuation.resume(throwing: VerificationError.ocrFailed)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: VerificationError.ocrFailed)
                    return
                }

                let text = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: text)
            }

            // Configure for accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: VerificationError.ocrFailed)
            }
        }
    }

    // MARK: - Extraction Methods

    /// Extracts monetary amount from OCR text
    private func extractAmount(from text: String) -> Double? {
        // Pattern matches: $XX.XX, $X,XXX.XX, XX.XX, etc.
        let patterns = [
            #"\$\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#,  // $1,234.56 or $12.34
            #"(?:total|amount|paid|payment)[:\s]+\$?\s*(\d{1,3}(?:,\d{3})*(?:\.\d{2})?)"#,  // Total: $12.34
            #"(\d{1,3}(?:,\d{3})*\.\d{2})\s*(?:USD|dollars?)?"#  // 12.34 USD
        ]

        let lowercaseText = text.lowercased()

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(lowercaseText.startIndex..., in: lowercaseText)
                if let match = regex.firstMatch(in: lowercaseText, options: [], range: range) {
                    if let amountRange = Range(match.range(at: 1), in: lowercaseText) {
                        let amountString = String(lowercaseText[amountRange])
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: "$", with: "")
                            .trimmingCharacters(in: .whitespaces)

                        if let amount = Double(amountString) {
                            return amount
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Extracts provider name from OCR text
    private func extractProvider(from text: String, expected: String) -> String? {
        let lowercaseText = text.lowercased()

        // First check for expected provider
        if let patterns = providerPatterns[expected.lowercased()] {
            for pattern in patterns {
                if lowercaseText.contains(pattern) {
                    return expected
                }
            }
        }

        // Then check all known providers
        for (provider, patterns) in providerPatterns {
            for pattern in patterns {
                if lowercaseText.contains(pattern) {
                    return provider
                }
            }
        }

        return nil
    }

    /// Extracts date from OCR text
    private func extractDate(from text: String) -> Date? {
        let datePatterns = [
            #"(\d{1,2})/(\d{1,2})/(\d{2,4})"#,  // MM/DD/YYYY
            #"(\d{1,2})-(\d{1,2})-(\d{2,4})"#,  // MM-DD-YYYY
            #"(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2}),?\s+(\d{4})"#  // Month DD, YYYY
        ]

        let dateFormatter = DateFormatter()

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(text.startIndex..., in: text)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    if let matchRange = Range(match.range, in: text) {
                        let dateString = String(text[matchRange])

                        // Try common date formats
                        let formats = ["MM/dd/yyyy", "MM-dd-yyyy", "MMM dd, yyyy", "MM/dd/yy"]
                        for format in formats {
                            dateFormatter.dateFormat = format
                            if let date = dateFormatter.date(from: dateString) {
                                return date
                            }
                        }
                    }
                }
            }
        }

        return nil
    }

    // MARK: - Confidence Calculation

    /// Calculates confidence score and identifies any flags
    private func calculateConfidence(
        rawText: String,
        extractedAmount: Double?,
        extractedProvider: String?,
        extractedDate: Date?,
        expectedAmount: Double,
        expectedProvider: String
    ) -> (Double, [ScreenshotVerificationResult.VerificationFlag]) {
        var confidence = 0.0
        var flags: [ScreenshotVerificationResult.VerificationFlag] = []

        // Amount matching (40% of score)
        if let amount = extractedAmount {
            let amountDiff = abs(amount - expectedAmount)
            let tolerance = expectedAmount * 0.05 // 5% tolerance

            if amountDiff <= tolerance {
                confidence += 0.4
            } else if amountDiff <= expectedAmount * 0.1 {
                confidence += 0.2
                flags.append(.amountMismatch(expected: expectedAmount, found: amount))
            } else {
                flags.append(.amountMismatch(expected: expectedAmount, found: amount))
            }
        } else {
            confidence += 0.1 // Partial credit for having text
        }

        // Provider matching (30% of score)
        if let provider = extractedProvider {
            if provider.lowercased() == expectedProvider.lowercased() {
                confidence += 0.3
            } else {
                confidence += 0.15
            }
        } else {
            flags.append(.providerNotFound)
        }

        // Date freshness (20% of score)
        if let date = extractedDate {
            let daysSince = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0

            if daysSince <= 3 {
                confidence += 0.2
            } else if daysSince <= 7 {
                confidence += 0.1
            } else {
                flags.append(.dateTooOld)
            }
        } else {
            confidence += 0.1 // Partial credit - date not required
        }

        // Text quality (10% of score)
        let wordCount = rawText.split(separator: " ").count
        if wordCount >= 10 {
            confidence += 0.1
        } else if wordCount >= 5 {
            confidence += 0.05
        }

        // Check for potential edit indicators
        if checkForEditIndicators(in: rawText) {
            flags.append(.possibleEdit)
            confidence *= 0.5 // Reduce confidence significantly
        }

        // Low confidence flag
        if confidence < 0.5 {
            flags.append(.lowConfidence)
        }

        return (min(1.0, confidence), flags)
    }

    /// Checks for indicators that the screenshot might have been edited
    private func checkForEditIndicators(in text: String) -> Bool {
        // Look for common editing artifacts
        let suspiciousPatterns = [
            "photoshop",
            "edited",
            "inspect element",
            "developer tools"
        ]

        let lowercaseText = text.lowercased()
        return suspiciousPatterns.contains { lowercaseText.contains($0) }
    }

    /// Determines verification status based on confidence and flags
    private func determineStatus(
        confidence: Double,
        flags: [ScreenshotVerificationResult.VerificationFlag]
    ) -> ScreenshotVerificationStatus {
        // Auto-reject if possible edit detected
        if flags.contains(where: {
            if case .possibleEdit = $0 { return true }
            return false
        }) {
            return .manualReview
        }

        // High confidence = auto-verify
        if confidence >= 0.7 && flags.isEmpty {
            return .autoVerified
        }

        // Medium confidence with minor flags = manual review
        if confidence >= 0.5 {
            return .manualReview
        }

        // Low confidence = rejected
        return .rejected
    }

    // MARK: - Storage Methods

    /// Uploads screenshot to Supabase storage
    private func uploadScreenshot(image: UIImage, swapId: UUID) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw VerificationError.imageLoadFailed
        }

        guard let session = try? await supabase.auth.session else {
            throw VerificationError.uploadFailed
        }

        let fileName = "\(session.user.id.uuidString)/\(swapId.uuidString)_\(Date().timeIntervalSince1970).jpg"

        do {
            _ = try await supabase.storage
                .from("swap-screenshots")
                .upload(
                    fileName,
                    data: imageData,
                    options: FileOptions(contentType: "image/jpeg")
                )

            // Get public URL
            let publicUrl = try supabase.storage
                .from("swap-screenshots")
                .getPublicURL(path: fileName)

            return publicUrl.absoluteString
        } catch {
            throw VerificationError.uploadFailed
        }
    }

    // MARK: - Utility Methods

    /// Resets the service state
    func reset() {
        lastResult = nil
        error = nil
        isProcessing = false
    }
}

// MARK: - Preview Helpers

extension ScreenshotVerificationService {
    /// Creates a mock result for previews
    static func mockResult() -> ScreenshotVerificationResult {
        ScreenshotVerificationResult(
            rawText: "Payment Confirmation\nNetflix\nAmount: $15.99\nDate: Dec 15, 2024\nStatus: Paid",
            extractedAmount: 15.99,
            extractedProvider: "netflix",
            extractedDate: Date(),
            confidence: 0.85,
            status: .autoVerified,
            flags: []
        )
    }
}
