//
//  AskBillixService.swift
//  Billix
//
//  Created by Claude Code on 2/5/26.
//  Service for Ask Billix AI chat API
//

import Foundation

/// Service for interacting with the Ask Billix AI chat endpoint
/// POST /api/v1/bills/ask
actor AskBillixService {
    static let shared = AskBillixService()

    private let baseURL = "https://www.billixapp.com/api/v1"
    private let session: URLSession

    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 90
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Request/Response Types

    struct AskRequest: Encodable {
        let question: String
        let billContext: String
        let conversationHistory: [MessageDTO]
    }

    struct MessageDTO: Codable {
        let role: String
        let content: String
    }

    struct AskResponse: Decodable {
        let answer: String
        let usage: Usage?

        struct Usage: Decodable {
            let prompt_tokens: Int
            let completion_tokens: Int
        }
    }

    struct ErrorResponse: Decodable {
        let error: String
    }

    // MARK: - Public API

    /// Send a question about a bill to the AI
    /// - Parameters:
    ///   - question: The user's question
    ///   - billContext: Raw extracted text or structured summary of the bill
    ///   - history: Previous messages in this conversation
    /// - Returns: The AI's response text
    func ask(
        question: String,
        billContext: String,
        history: [AskBillixMessage]
    ) async throws -> String {
        guard let url = URL(string: "\(baseURL)/bills/ask") else {
            throw AskBillixError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get auth token from Supabase
        guard let authSession = try? await SupabaseService.shared.client.auth.session else {
            throw AskBillixError.unauthorized
        }
        let token = authSession.accessToken
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Build request body
        let body = AskRequest(
            question: question,
            billContext: billContext,
            conversationHistory: history.map {
                MessageDTO(role: $0.role == .user ? "user" : "assistant", content: $0.content)
            }
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AskBillixError.serverError
        }

        switch httpResponse.statusCode {
        case 200:
            let result = try JSONDecoder().decode(AskResponse.self, from: data)
            return result.answer
        case 401:
            throw AskBillixError.unauthorized
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
            throw AskBillixError.rateLimited(retryAfterSeconds: Int(retryAfter ?? "60") ?? 60)
        case 400:
            let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw AskBillixError.validationError(errorResponse?.error ?? "Invalid request")
        case 503:
            throw AskBillixError.serviceUnavailable
        default:
            throw AskBillixError.serverError
        }
    }

    // MARK: - Errors

    enum AskBillixError: Error, LocalizedError {
        case invalidURL
        case unauthorized
        case rateLimited(retryAfterSeconds: Int)
        case validationError(String)
        case serviceUnavailable
        case serverError

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid API URL"
            case .unauthorized:
                return "Please sign in to use Ask Billix."
            case .rateLimited(let seconds):
                return "Too many questions! Please wait \(seconds) seconds."
            case .validationError(let msg):
                return msg
            case .serviceUnavailable:
                return "Billix is busy. Please try again in a moment."
            case .serverError:
                return "Something went wrong. Please try again."
            }
        }
    }
}
