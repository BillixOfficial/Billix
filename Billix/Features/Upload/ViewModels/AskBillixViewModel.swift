//
//  AskBillixViewModel.swift
//  Billix
//
//  Created by Claude Code on 2/3/26.
//

import SwiftUI
import SwiftData

// MARK: - Message Model

struct AskBillixMessage: Identifiable, Codable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date

    enum Role: String, Codable {
        case user
        case assistant
    }

    init(role: Role, content: String) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
    }
}

// MARK: - ViewModel

@MainActor
class AskBillixViewModel: ObservableObject {
    @Published var messages: [AskBillixMessage] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var hasStartedChat = false
    @Published var errorMessage: String?

    private let analysis: BillAnalysis
    private let billId: UUID?
    private var chatSession: StoredChatSession?
    var modelContext: ModelContext?

    init(analysis: BillAnalysis, billId: UUID? = nil) {
        self.analysis = analysis
        self.billId = billId
    }

    // MARK: - Load Existing Session

    func loadExistingSession() {
        guard let billId = billId, let context = modelContext else { return }

        let now = Date()
        let targetBillId = billId

        // Fetch non-expired session for this bill
        let descriptor = FetchDescriptor<StoredChatSession>(
            predicate: #Predicate<StoredChatSession> { session in
                session.billId == targetBillId && session.expiresAt > now
            }
        )

        do {
            if let session = try context.fetch(descriptor).first {
                self.chatSession = session
                // Decrypt and load messages
                Task {
                    if let decrypted = try? await EncryptionService.shared.decrypt(session.messagesData),
                       let loaded = try? JSONDecoder().decode([AskBillixMessage].self, from: decrypted) {
                        await MainActor.run {
                            self.messages = loaded
                            self.hasStartedChat = !loaded.isEmpty
                        }
                    }
                }
            }
        } catch {
            print("Failed to load chat session: \(error)")
        }
    }

    // MARK: - User Name

    var userFirstName: String {
        guard let name = AuthService.shared.currentUser?.displayName else { return "there" }
        let parts = name.split(separator: " ")
        return parts.first.map(String.init) ?? "there"
    }

    // MARK: - Suggested Questions

    var suggestedQuestions: [String] {
        var questions = [
            "Why is my bill high?",
            "Explain my charges",
            "How can I save?"
        ]
        if let redFlags = analysis.redFlags, !redFlags.isEmpty {
            questions.append("What are the red flags?")
        }
        if analysis.marketplaceComparison != nil {
            questions.append("How do I compare to others?")
        }
        return questions
    }

    // MARK: - Send Message

    func sendMessage(_ text: String? = nil) {
        let content = (text ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let userMessage = AskBillixMessage(role: .user, content: content)
        messages.append(userMessage)
        inputText = ""
        errorMessage = nil

        if !hasStartedChat {
            withAnimation(.easeInOut(duration: 0.3)) {
                hasStartedChat = true
            }
        }

        isTyping = true

        Task {
            do {
                // Only send last 20 messages as history (API limit)
                let previousMessages = Array(messages.dropLast())
                let trimmedHistory = previousMessages.suffix(20)

                let response = try await AskBillixService.shared.ask(
                    question: content,
                    billContext: buildBillContext(),
                    history: Array(trimmedHistory)
                )

                let assistantMessage = AskBillixMessage(role: .assistant, content: response)
                messages.append(assistantMessage)
                saveSession()
            } catch let error as AskBillixService.AskBillixError {
                handleError(error)
            } catch {
                errorMessage = "Something went wrong. Please try again."
                // Remove the user message that failed
                if messages.last?.role == .user {
                    messages.removeLast()
                }
            }
            isTyping = false
        }
    }

    // MARK: - Error Handling

    private func handleError(_ error: AskBillixService.AskBillixError) {
        errorMessage = error.localizedDescription
        // Remove the user message that failed
        if messages.last?.role == .user {
            messages.removeLast()
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    // MARK: - Bill Context

    private func buildBillContext() -> String {
        var context = ""

        // Use raw extracted text if available (richer bill details)
        if let raw = analysis.rawExtractedText, !raw.isEmpty {
            context = raw
        } else {
            // Fallback to structured summary
            var parts: [String] = []
            parts.append("Provider: \(analysis.provider)")
            parts.append("Amount: $\(String(format: "%.2f", analysis.amount))")
            parts.append("Category: \(analysis.category)")
            parts.append("Bill Date: \(analysis.billDate)")
            if let dueDate = analysis.dueDate {
                parts.append("Due Date: \(dueDate)")
            }

            if let summary = analysis.plainEnglishSummary {
                parts.append("Summary: \(summary)")
            }

            if !analysis.lineItems.isEmpty {
                let items = analysis.lineItems.map { "\($0.description): $\(String(format: "%.2f", $0.amount))" }
                parts.append("Line Items: \(items.joined(separator: ", "))")
            }

            if let redFlags = analysis.redFlags, !redFlags.isEmpty {
                let flags = redFlags.map { $0.description }
                parts.append("Red Flags: \(flags.joined(separator: "; "))")
            }

            context = parts.joined(separator: " | ")
        }

        // ALWAYS append marketplace comparison OR explain why it's missing
        if let comparison = analysis.marketplaceComparison {
            context += "\n\n--- BILLIX COMPARISON DATA ---\n"
            context += "Your bill: $\(String(format: "%.2f", analysis.amount))\n"
            context += "Billix Average: $\(String(format: "%.2f", comparison.areaAverage))\n"
            context += "Difference: \(String(format: "%.0f", abs(comparison.percentDiff)))% \(comparison.position.rawValue) average\n"
            if let sampleSize = comparison.sampleSize {
                let region = comparison.state ?? comparison.zipPrefix
                context += "Based on \(sampleSize) Billix users in \(region)"
            }
        } else {
            context += "\n\n--- BILLIX COMPARISON DATA ---\n"
            context += "No marketplace comparison available yet. Not enough Billix users have uploaded similar bills in this category/region to generate a meaningful comparison."
        }

        return context
    }

    // MARK: - Session Persistence

    private func saveSession() {
        guard let billId = billId, let context = modelContext else { return }

        Task {
            if chatSession == nil {
                let newSession = StoredChatSession(billId: billId)
                context.insert(newSession)
                chatSession = newSession
            }

            // Encrypt messages before saving
            if let encoded = try? JSONEncoder().encode(messages),
               let encrypted = try? await EncryptionService.shared.encrypt(encoded) {
                chatSession?.messagesData = encrypted
            }

            try? context.save()
        }
    }
}
