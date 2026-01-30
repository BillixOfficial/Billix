//
//  ReportPostSheet.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Sheet for reporting a community post with reason categories
//

import SwiftUI

// MARK: - Report Reason Enum

enum ReportReason: String, CaseIterable, Identifiable {
    case spam = "spam"
    case harassment = "harassment"
    case hateSpech = "hate_speech"
    case misinformation = "misinformation"
    case inappropriate = "inappropriate"
    case other = "other"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .spam: return "Spam"
        case .harassment: return "Harassment or Bullying"
        case .hateSpech: return "Hate Speech"
        case .misinformation: return "Misinformation"
        case .inappropriate: return "Inappropriate Content"
        case .other: return "Other"
        }
    }

    var description: String {
        switch self {
        case .spam: return "Unwanted advertising or repetitive content"
        case .harassment: return "Targeting, intimidating, or threatening someone"
        case .hateSpech: return "Attacks based on race, religion, gender, etc."
        case .misinformation: return "False or misleading information"
        case .inappropriate: return "Content that violates community guidelines"
        case .other: return "Something else not listed above"
        }
    }

    var icon: String {
        switch self {
        case .spam: return "envelope.badge"
        case .harassment: return "exclamationmark.bubble"
        case .hateSpech: return "hand.raised.slash"
        case .misinformation: return "info.circle"
        case .inappropriate: return "eye.slash"
        case .other: return "ellipsis.circle"
        }
    }
}

// MARK: - Report Post Sheet

struct ReportPostSheet: View {
    let post: CommunityPost
    let onSubmit: (ReportReason, String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedReason: ReportReason?
    @State private var additionalDetails: String = ""
    @State private var isSubmitting = false
    @State private var showConfirmation = false
    @FocusState private var isDetailsFocused: Bool

    private let maxDetailsLength = 500

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Why are you reporting this post?")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(hex: "#1A1A1A"))

                        Text("Select a reason below. Your report is anonymous and will be reviewed by our team.")
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#6B7280"))
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Reason options
                    VStack(spacing: 12) {
                        ForEach(ReportReason.allCases) { reason in
                            reasonCard(reason)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Additional details (optional)
                    if selectedReason != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Additional details (optional)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "#374151"))

                                Spacer()

                                Text("\(additionalDetails.count)/\(maxDetailsLength)")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "#9CA3AF"))
                            }

                            TextEditor(text: $additionalDetails)
                                .font(.system(size: 15))
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color(hex: "#F9FAFB"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(hex: "#E5E7EB"), lineWidth: 1)
                                )
                                .focused($isDetailsFocused)
                                .onChange(of: additionalDetails) { _, newValue in
                                    if newValue.count > maxDetailsLength {
                                        additionalDetails = String(newValue.prefix(maxDetailsLength))
                                    }
                                }
                        }
                        .padding(.horizontal, 20)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(Color(hex: "#F5F5F7"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "#6B7280"))
                }

                ToolbarItem(placement: .principal) {
                    Text("Report Post")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .safeAreaInset(edge: .bottom) {
                // Submit button
                VStack(spacing: 0) {
                    Divider()

                    Button {
                        submitReport()
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Submit Report")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            selectedReason != nil ? Color(hex: "#EF4444") : Color(hex: "#D1D5DB")
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(selectedReason == nil || isSubmitting)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(Color.white)
                }
            }
            .alert("Report Submitted", isPresented: $showConfirmation) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep our community safe. We'll review this report and take action if needed.")
            }
        }
    }

    // MARK: - Reason Card

    private func reasonCard(_ reason: ReportReason) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedReason == reason {
                    selectedReason = nil
                } else {
                    selectedReason = reason
                }
            }
        } label: {
            HStack(spacing: 14) {
                // Icon
                Image(systemName: reason.icon)
                    .font(.system(size: 20))
                    .foregroundColor(selectedReason == reason ? .white : Color(hex: "#6B7280"))
                    .frame(width: 44, height: 44)
                    .background(
                        selectedReason == reason ? Color(hex: "#EF4444") : Color(hex: "#F3F4F6")
                    )
                    .clipShape(Circle())

                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayTitle)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#1A1A1A"))

                    Text(reason.description)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "#6B7280"))
                        .lineLimit(2)
                }

                Spacer()

                // Checkmark
                if selectedReason == reason {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color(hex: "#EF4444"))
                }
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedReason == reason ? Color(hex: "#EF4444") : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit

    private func submitReport() {
        guard let reason = selectedReason else { return }

        isSubmitting = true

        // Call the submit handler
        let details = additionalDetails.isEmpty ? nil : additionalDetails
        onSubmit(reason, details)

        // Show confirmation after a brief delay
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSubmitting = false
            showConfirmation = true
        }
    }
}

// MARK: - Preview

#Preview("Report Post Sheet") {
    ReportPostSheet(
        post: CommunityPost.mockPosts[0],
        onSubmit: { reason, details in
        }
    )
}
