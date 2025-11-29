//
//  UploadModels.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import Foundation

// MARK: - Upload Source

enum UploadSource: String, Codable, CaseIterable {
    case quickAdd = "quickAdd"
    case camera = "camera"
    case photos = "photos"
    case documentScanner = "documentScanner"
    case documentPicker = "documentPicker"

    var displayName: String {
        switch self {
        case .quickAdd: return "Quick Add"
        case .camera: return "Full Analysis"
        case .photos: return "Full Analysis"
        case .documentScanner: return "Full Analysis"
        case .documentPicker: return "Full Analysis"
        }
    }

    var icon: String {
        switch self {
        case .quickAdd: return "bolt.fill"
        case .camera: return "camera.fill"
        case .photos: return "photo.on.rectangle"
        case .documentScanner: return "doc.text.viewfinder"
        case .documentPicker: return "folder.fill"
        }
    }
}

// MARK: - Upload Status

enum UploadStatus: String, Codable {
    case processing = "processing"
    case analyzed = "analyzed"
    case needsConfirmation = "needsConfirmation"
    case failed = "failed"

    var displayName: String {
        switch self {
        case .processing: return "Processing..."
        case .analyzed: return "Analyzed"
        case .needsConfirmation: return "Needs Confirmation"
        case .failed: return "Failed"
        }
    }

    var color: String {
        switch self {
        case .processing: return "orange"
        case .analyzed: return "green"
        case .needsConfirmation: return "yellow"
        case .failed: return "red"
        }
    }

    var icon: String {
        switch self {
        case .processing: return "hourglass"
        case .analyzed: return "checkmark.circle.fill"
        case .needsConfirmation: return "exclamationmark.triangle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Recent Upload

struct RecentUpload: Identifiable, Codable {
    let id: UUID
    let provider: String
    let amount: Double
    let source: UploadSource
    let status: UploadStatus
    let uploadDate: Date
    let thumbnailName: String?

    var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }

    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: uploadDate, relativeTo: Date())
    }
}

// MARK: - Upload Error

enum UploadError: LocalizedError {
    case validationFailed(String)
    case uploadFailed(String)
    case networkError(String)
    case unauthorized
    case serverError(String)
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "Validation Error: \(message)"
        case .uploadFailed(let message):
            return "Upload Failed: \(message)"
        case .networkError(let message):
            return "Network Error: \(message)"
        case .unauthorized:
            return "Unauthorized: Please log in again"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}
