//
//  TermsProposalView.swift
//  Billix
//
//  Phase 2: Handshake
//  Allows the supporter to propose simple terms (deadline, proof type)
//  Simplified from DealNegotiationView - no back-and-forth negotiation
//

import SwiftUI

struct TermsProposalView: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDeadline: Date
    @State private var selectedProofType: ProofType = .screenshot
    @State private var isSubmitting = false
    @State private var error: String?

    init(connection: Connection, viewModel: ConnectionDetailViewModel) {
        self.connection = connection
        self.viewModel = viewModel

        // Default deadline: 48 hours from now
        let defaultDeadline = Calendar.current.date(byAdding: .hour, value: 48, to: Date()) ?? Date()
        self._selectedDeadline = State(initialValue: defaultDeadline)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Combined Terms Form
                    ProposalFormCard(
                        selectedDeadline: $selectedDeadline,
                        selectedProofType: $selectedProofType,
                        billDueDate: viewModel.bill?.dueDate
                    )

                    // Live Preview Summary
                    ProposalPreviewCard(
                        deadline: selectedDeadline,
                        proofType: selectedProofType
                    )

                    // Error Display
                    if let error = error {
                        ProposalErrorBanner(message: error)
                    }

                    // Submit Button
                    ProposalSubmitButton(
                        isSubmitting: isSubmitting,
                        onSubmit: submitTerms
                    )

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Propose Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color.billixDarkTeal)
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func submitTerms() {
        isSubmitting = true
        error = nil

        Task {
            do {
                // Get the bill amount from the bill, or use a default
                let billAmount = viewModel.bill?.amount ?? Decimal(0)

                let termsInput = ConnectionTermsInput(
                    billAmount: billAmount,
                    deadline: selectedDeadline,
                    proofRequired: selectedProofType
                )

                _ = try await TermsService.shared.proposeTerms(
                    connectionId: connection.id,
                    terms: termsInput
                )

                // Refresh the view model
                await viewModel.loadDetails()

                isSubmitting = false
                dismiss()
            } catch {
                self.error = error.localizedDescription
                isSubmitting = false
            }
        }
    }
}

// MARK: - Proposal Form Card

struct ProposalFormCard: View {
    @Binding var selectedDeadline: Date
    @Binding var selectedProofType: ProofType
    let billDueDate: Date?

    var minDate: Date {
        Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    }

    var maxDate: Date {
        let sevenDaysOut = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        var result = sevenDaysOut

        if let dueDate = billDueDate {
            result = min(sevenDaysOut, dueDate)
        }

        // Ensure maxDate is never less than minDate to prevent range crash
        return max(result, minDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "doc.badge.clock")
                    .font(.system(size: 18))
                Text("Set Payment Terms")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            VStack(spacing: 24) {
                // Deadline Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 14))
                            .foregroundColor(Color.billixDarkTeal)
                        Text("When will you pay?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.billixDarkTeal)
                    }

                    DatePicker(
                        "Deadline",
                        selection: $selectedDeadline,
                        in: minDate...maxDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(Color.billixDarkTeal)

                    // Quick Select Buttons
                    HStack(spacing: 10) {
                        ProposalQuickButton(title: "24h", hours: 24, selectedDeadline: $selectedDeadline)
                        ProposalQuickButton(title: "48h", hours: 48, selectedDeadline: $selectedDeadline)
                        ProposalQuickButton(title: "3 days", hours: 72, selectedDeadline: $selectedDeadline)
                    }
                }

                Divider()

                // Proof Type Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.billixDarkTeal)
                        Text("How will you prove payment?")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color.billixDarkTeal)
                    }

                    // Proof type options as cards
                    VStack(spacing: 8) {
                        ForEach(ProofType.allCases, id: \.self) { proofType in
                            ProofTypeOption(
                                proofType: proofType,
                                isSelected: selectedProofType == proofType,
                                onSelect: { selectedProofType = proofType }
                            )
                        }
                    }
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

struct ProposalQuickButton: View {
    let title: String
    let hours: Int
    @Binding var selectedDeadline: Date

    var isSelected: Bool {
        let targetDate = Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date()
        return abs(selectedDeadline.timeIntervalSince(targetDate)) < 3600
    }

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDeadline = Calendar.current.date(byAdding: .hour, value: hours, to: Date()) ?? Date()
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color.billixDarkTeal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    isSelected ?
                    AnyView(
                        LinearGradient(
                            colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    ) :
                    AnyView(Color.billixDarkTeal.opacity(0.08))
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct ProofTypeOption: View {
    let proofType: ProofType
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.billixMoneyGreen : Color.gray.opacity(0.1))
                        .frame(width: 36, height: 36)

                    Image(systemName: proofType.icon)
                        .font(.system(size: 14))
                        .foregroundColor(isSelected ? .white : .gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(proofType.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isSelected ? Color.billixDarkTeal : .primary)

                    Text(proofType.shortDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.billixMoneyGreen)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.billixMoneyGreen.opacity(0.08) : Color.gray.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.billixMoneyGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Proposal Preview Card

struct ProposalPreviewCard: View {
    let deadline: Date
    let proofType: ProofType

    var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: deadline)
    }

    var relativeDeadline: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: deadline, relativeTo: Date())
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "eye.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixGoldenAmber)
                Text("Preview")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.billixDarkTeal)
                Spacer()
            }

            HStack(spacing: 16) {
                // Deadline preview
                VStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.billixDarkTeal)
                    Text(relativeDeadline)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.billixDarkTeal)
                    Text("Deadline")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.billixDarkTeal.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                // Proof type preview
                VStack(spacing: 4) {
                    Image(systemName: proofType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(Color.billixMoneyGreen)
                    Text(proofType.shortLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.billixMoneyGreen)
                    Text("Proof")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.billixMoneyGreen.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Info note
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                Text("The requester has 24 hours to accept or decline")
                    .font(.system(size: 11))
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Error Banner

struct ProposalErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
            Text(message)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "#C45C5C"), Color(hex: "#C45C5C").opacity(0.9)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Submit Button

struct ProposalSubmitButton: View {
    let isSubmitting: Bool
    let onSubmit: () -> Void

    var body: some View {
        Button(action: onSubmit) {
            HStack(spacing: 10) {
                if isSubmitting {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                }
                Text(isSubmitting ? "Submitting..." : "Send Proposal")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSubmitting ?
                AnyView(Color.gray) :
                AnyView(
                    LinearGradient(
                        colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: isSubmitting ? .clear : Color.billixMoneyGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isSubmitting)
    }
}

// MARK: - ProofType Extensions

extension ProofType {
    var shortDescription: String {
        switch self {
        case .screenshot:
            return "Payment confirmation screenshot"
        case .screenshotWithConfirmation:
            return "Screenshot + requester confirmation"
        case .utilityPortal:
            return "Screenshot from utility portal"
        case .bankStatement:
            return "Bank statement showing payment"
        }
    }

    var shortLabel: String {
        switch self {
        case .screenshot: return "Screenshot"
        case .screenshotWithConfirmation: return "Screenshot+"
        case .utilityPortal: return "Portal"
        case .bankStatement: return "Statement"
        }
    }
}

// MARK: - Errors

enum TermsProposalError: LocalizedError {
    case billNotLoaded
    case invalidDeadline
    case submissionFailed(String)

    var errorDescription: String? {
        switch self {
        case .billNotLoaded:
            return "Bill details not loaded. Please try again."
        case .invalidDeadline:
            return "Please select a valid deadline."
        case .submissionFailed(let message):
            return "Failed to propose terms: \(message)"
        }
    }
}

// MARK: - Preview

#Preview {
    TermsProposalView(
        connection: Connection.mockHandshake(),
        viewModel: ConnectionDetailViewModel(connection: Connection.mockHandshake())
    )
}
