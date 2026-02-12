//
//  AskOwnerSheet.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Pre-set questions for anonymous inquiry system
enum PresetQuestion: String, CaseIterable, Identifiable {
    case threatCancel = "Did you have to threaten to cancel?"
    case newCustomer = "Are you a new customer?"
    case studentDiscount = "Is this a student discount?"
    case bundleMobile = "Did you bundle mobile?"
    case switchedFirst = "Did you switch providers first?"
    case howLong = "How long have you been a customer?"

    var id: String { rawValue }
}

/// Sheet for asking anonymous questions to deal owners
struct AskOwnerSheet: View {
    let listing: BillListing
    @Environment(\.dismiss) private var dismiss

    @State private var selectedQuestion: PresetQuestion?
    @State private var isSending: Bool = false
    @State private var sendSuccess: Bool = false

    var body: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            // Header
            header

            if sendSuccess {
                successView
            } else {
                // Explanation
                Text("Ask anonymous questions about this deal. The owner will receive a notification and can answer with one tap.")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                // Question options
                questionsList

                Spacer()

                // Send button
                sendButton
            }
        }
        .padding(MarketplaceTheme.Spacing.lg)
    }

    private var header: some View {
        VStack(spacing: MarketplaceTheme.Spacing.xs) {
            HStack(spacing: MarketplaceTheme.Spacing.sm) {
                // Owner avatar
                ZStack {
                    Circle()
                        .fill(MarketplaceTheme.Colors.secondary.opacity(0.2))
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(MarketplaceTheme.Colors.secondary)
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Ask")
                        .font(.system(size: MarketplaceTheme.Typography.body))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                    Text(listing.sellerHandle)
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                }
            }

            // Deal context
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: listing.providerLogoName)
                    .font(.system(size: 12))
                Text(listing.providerName)
                Text("•")
                Text(String(format: "$%.2f/mo", listing.askPrice))
            }
            .font(.system(size: MarketplaceTheme.Typography.caption))
            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
    }

    private var questionsList: some View {
        VStack(spacing: MarketplaceTheme.Spacing.xs) {
            ForEach(PresetQuestion.allCases) { question in
                questionOption(question)
            }
        }
    }

    private func questionOption(_ question: PresetQuestion) -> some View {
        Button {
            withAnimation(MarketplaceTheme.Animation.quick) {
                selectedQuestion = question
            }
        } label: {
            HStack {
                Text(question.rawValue)
                    .font(.system(size: MarketplaceTheme.Typography.callout))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if selectedQuestion == question {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                } else {
                    Circle()
                        .stroke(MarketplaceTheme.Colors.textTertiary, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(selectedQuestion == question
                          ? MarketplaceTheme.Colors.primary.opacity(0.1)
                          : MarketplaceTheme.Colors.backgroundSecondary)
                    .stroke(selectedQuestion == question
                            ? MarketplaceTheme.Colors.primary.opacity(0.3)
                            : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var sendButton: some View {
        Button {
            sendQuestion()
        } label: {
            HStack {
                if isSending {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Send Question")
                }
            }
            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                    .fill(selectedQuestion != nil
                          ? MarketplaceTheme.Colors.primary
                          : MarketplaceTheme.Colors.textTertiary)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(selectedQuestion == nil || isSending)
    }

    private var successView: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(MarketplaceTheme.Colors.success)

            Text("Question Sent!")
                .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            Text("You'll be notified when \(listing.sellerHandle) responds.")
                .font(.system(size: MarketplaceTheme.Typography.body))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Points earned
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: "star.fill")
                    .foregroundStyle(MarketplaceTheme.Colors.accent)
                Text("+5 points for engaging!")
            }
            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
            .foregroundStyle(MarketplaceTheme.Colors.accent)
            .padding(MarketplaceTheme.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.accent.opacity(0.1))
            )

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MarketplaceTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                            .fill(MarketplaceTheme.Colors.primary)
                    )
            }
        }
    }

    private func sendQuestion() {
        guard selectedQuestion != nil else { return }
        isSending = true

        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                isSending = false
                withAnimation {
                    sendSuccess = true
                }
            }
        }
    }
}

struct AskOwnerSheet_Previews: PreviewProvider {
    static var previews: some View {
        AskOwnerSheet(listing: MockMarketplaceData.billListings[0])
    }
}
