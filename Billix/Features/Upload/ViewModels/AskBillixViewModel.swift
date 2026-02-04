//
//  AskBillixViewModel.swift
//  Billix
//
//  Created by Claude Code on 2/3/26.
//

import SwiftUI

// MARK: - Message Model

struct AskBillixMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()

    enum Role {
        case user
        case assistant
    }
}

// MARK: - ViewModel

@MainActor
class AskBillixViewModel: ObservableObject {
    @Published var messages: [AskBillixMessage] = []
    @Published var inputText = ""
    @Published var isTyping = false
    @Published var hasStartedChat = false

    private let analysis: BillAnalysis

    init(analysis: BillAnalysis) {
        self.analysis = analysis
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
            questions.append("Am I being overcharged?")
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

        if !hasStartedChat {
            withAnimation(.easeInOut(duration: 0.3)) {
                hasStartedChat = true
            }
        }

        isTyping = true

        Task {
            let response = await generateAIResponse(for: content)
            isTyping = false
            let assistantMessage = AskBillixMessage(role: .assistant, content: response)
            messages.append(assistantMessage)
        }
    }

    // MARK: - Mock AI Response
    // TODO: Replace with Supabase Edge Function

    private func generateAIResponse(for query: String) async -> String {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)

        let lowered = query.lowercased()
        let context = buildBillContext()

        if lowered.contains("high") || lowered.contains("expensive") || lowered.contains("much") {
            var response = "Looking at your \(analysis.provider) bill of $\(String(format: "%.2f", analysis.amount)):\n\n"
            if let comparison = analysis.marketplaceComparison {
                let diff = abs(comparison.percentDiff)
                if comparison.position == .above {
                    response += "Your bill is \(String(format: "%.0f", diff))% above the area average of $\(String(format: "%.2f", comparison.areaAverage)). "
                } else {
                    response += "Your bill is actually at or below the area average of $\(String(format: "%.2f", comparison.areaAverage)), so it's not unusually high. "
                }
            }
            if let topItem = analysis.lineItems.max(by: { $0.amount < $1.amount }) {
                response += "The largest charge is \"\(topItem.description)\" at $\(String(format: "%.2f", topItem.amount))."
            }
            return response
        }

        if lowered.contains("charges") || lowered.contains("breakdown") || lowered.contains("explain") {
            var response = "Here's a breakdown of your \(analysis.provider) bill:\n\n"
            for item in analysis.lineItems.prefix(5) {
                response += "• \(item.description): $\(String(format: "%.2f", item.amount))"
                if let explanation = item.explanation {
                    response += " — \(explanation)"
                }
                response += "\n"
            }
            if analysis.lineItems.count > 5 {
                response += "\n...and \(analysis.lineItems.count - 5) more charges."
            }
            return response
        }

        if lowered.contains("save") || lowered.contains("lower") || lowered.contains("reduce") {
            var response = "Here are some ways to save on your \(analysis.provider) bill:\n\n"
            if let savings = analysis.savingsOpportunities, !savings.isEmpty {
                for item in savings.prefix(3) {
                    response += "• \(item.action)"
                    if let amount = item.potentialSavings {
                        response += " (save up to $\(String(format: "%.2f", amount)))"
                    }
                    response += "\n"
                }
            } else {
                response += "• Call your provider and ask about current promotions\n"
                response += "• Review your plan to make sure you're not paying for unused services\n"
                response += "• Compare rates with other providers in your area"
            }
            return response
        }

        if lowered.contains("red flag") || lowered.contains("flag") || lowered.contains("warning") {
            if let redFlags = analysis.redFlags, !redFlags.isEmpty {
                var response = "I found \(redFlags.count) red flag\(redFlags.count == 1 ? "" : "s") on your bill:\n\n"
                for flag in redFlags {
                    response += "⚠️ \(flag.description)\n→ \(flag.recommendation)\n\n"
                }
                return response
            } else {
                return "Good news! I didn't find any red flags on your \(analysis.provider) bill. Everything looks standard."
            }
        }

        if lowered.contains("overcharg") || lowered.contains("comparison") || lowered.contains("average") {
            if let comparison = analysis.marketplaceComparison {
                let diff = abs(comparison.percentDiff)
                if comparison.position == .above {
                    return "Based on \(comparison.sampleSize ?? 0) bills in your area (zip prefix \(comparison.zipPrefix)), you're paying \(String(format: "%.0f", diff))% more than the average of $\(String(format: "%.2f", comparison.areaAverage)). You could potentially save $\(String(format: "%.2f", analysis.amount - comparison.areaAverage)) per billing cycle by switching or negotiating."
                } else {
                    return "You're actually paying at or below the area average of $\(String(format: "%.2f", comparison.areaAverage)). You're getting a fair deal compared to others in your area!"
                }
            }
            return "I don't have comparison data for this bill type yet. Try scanning more bills to build up your comparison history."
        }

        // Default response
        return "Great question about your \(analysis.provider) bill! Here's what I can tell you:\n\n\(context)\n\nWould you like me to go deeper on any specific charge or topic?"
    }

    // MARK: - Bill Context Summary

    private func buildBillContext() -> String {
        var parts: [String] = []
        parts.append("Provider: \(analysis.provider)")
        parts.append("Total: $\(String(format: "%.2f", analysis.amount))")
        parts.append("Category: \(analysis.category)")
        parts.append("\(analysis.lineItems.count) line items")

        if let comparison = analysis.marketplaceComparison {
            parts.append("Area average: $\(String(format: "%.2f", comparison.areaAverage)) (\(comparison.position.rawValue))")
        }
        if let redFlags = analysis.redFlags, !redFlags.isEmpty {
            parts.append("\(redFlags.count) red flag(s)")
        }
        if let savings = analysis.savingsOpportunities, !savings.isEmpty {
            parts.append("\(savings.count) savings opportunity(ies)")
        }

        return parts.joined(separator: " | ")
    }
}
