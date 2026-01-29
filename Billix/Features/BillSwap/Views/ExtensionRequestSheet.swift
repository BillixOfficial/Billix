//
//  ExtensionRequestSheet.swift
//  Billix
//
//  Sheet for requesting or responding to deadline extensions
//

import SwiftUI

// MARK: - Extension Request Sheet

struct ExtensionRequestSheet: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let swapId: UUID
    let currentDeadline: Date
    let onRequestSent: () -> Void

    // MARK: - State

    @State private var selectedReason: ExtensionReason = .payScheduleConflict
    @State private var customNote: String = ""
    @State private var selectedDuration: Int = 48 // hours
    @State private var showPartialPayment = false
    @State private var partialAmount: String = ""
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showingConfirmation = false

    // MARK: - Computed Properties

    private var newDeadline: Date {
        Calendar.current.date(byAdding: .hour, value: selectedDuration, to: currentDeadline) ?? currentDeadline
    }

    private var daysExtension: Int {
        Calendar.current.dateComponents([.day], from: currentDeadline, to: newDeadline).day ?? 0
    }

    private var isValid: Bool {
        if selectedReason == .other && customNote.isEmpty {
            return false
        }
        return selectedDuration > 0 && selectedDuration <= ExtensionService.maxExtensionDays * 24
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Reason selection
                    reasonSection

                    // Custom note (if other)
                    if selectedReason == .other {
                        customNoteSection
                    }

                    // Duration selection
                    durationSection

                    // Partial payment option
                    partialPaymentSection

                    // Summary
                    summarySection

                    // Submit button
                    submitButton
                }
                .padding()
            }
            .background(Color.billixCreamBeige.ignoresSafeArea())
            .navigationTitle("Request Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Confirm Request", isPresented: $showingConfirmation) {
                Button("Send Request", role: .none) {
                    Task { await submitRequest() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your partner will have 24 hours to approve or deny this request.")
            }
            .overlay {
                if isLoading {
                    loadingOverlay
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.billixGoldenAmber)

            Text("Need More Time?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.billixDarkTeal)

            Text("Request an extension on your deadline. Your partner must approve.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Current deadline
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                Text("Current deadline:")
                    .foregroundColor(.secondary)
                Text(formatDeadline(currentDeadline))
                    .fontWeight(.semibold)
                    .foregroundColor(.billixDarkTeal)
            }
            .font(.caption)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
        }
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Why do you need more time?", icon: "questionmark.circle")

            VStack(spacing: 8) {
                ForEach(ExtensionReason.allCases, id: \.self) { reason in
                    ReasonOptionRow(
                        reason: reason,
                        isSelected: selectedReason == reason
                    ) {
                        selectedReason = reason
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Custom Note Section

    private var customNoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Please explain")
                .font(.caption)
                .foregroundColor(.secondary)

            TextEditor(text: $customNote)
                .frame(height: 80)
                .padding(8)
                .background(Color.billixCreamBeige.opacity(0.5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.billixDarkTeal.opacity(0.2), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("How much time do you need?", icon: "hourglass")

            // Preset options
            HStack(spacing: 8) {
                ForEach(ExtensionRequestInput.presetDurations, id: \.hours) { preset in
                    DurationPill(
                        name: preset.name,
                        isSelected: selectedDuration == preset.hours
                    ) {
                        selectedDuration = preset.hours
                    }
                }
            }

            // New deadline preview
            HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(.billixMoneyGreen)

                Text("New deadline:")
                    .foregroundColor(.secondary)

                Spacer()

                Text(formatDeadline(newDeadline))
                    .fontWeight(.semibold)
                    .foregroundColor(.billixMoneyGreen)
            }
            .font(.subheadline)
            .padding()
            .background(Color.billixMoneyGreen.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Partial Payment Section

    private var partialPaymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $showPartialPayment) {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.billixMoneyGreen)
                    VStack(alignment: .leading) {
                        Text("Offer Partial Payment")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Show good faith with a partial payment now")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .tint(.billixMoneyGreen)

            if showPartialPayment {
                HStack {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.billixMoneyGreen)

                    TextField("0.00", text: $partialAmount)
                        .font(.title2)
                        .keyboardType(.decimalPad)
                }
                .padding()
                .background(Color.billixCreamBeige.opacity(0.5))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Request Summary", icon: "doc.text")

            VStack(spacing: 8) {
                SummaryRow(label: "Reason", value: selectedReason.displayName)
                SummaryRow(label: "Extension", value: "\(daysExtension) day\(daysExtension == 1 ? "" : "s")")
                SummaryRow(label: "New Deadline", value: formatDeadline(newDeadline))

                if showPartialPayment, let amount = Decimal(string: partialAmount), amount > 0 {
                    SummaryRow(label: "Partial Payment", value: formatAmount(amount))
                }
            }
        }
        .padding()
        .background(Color.billixDarkTeal.opacity(0.05))
        .cornerRadius(16)
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            showingConfirmation = true
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                Text("Send Request")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? Color.billixGoldenAmber : Color.gray)
            .cornerRadius(16)
        }
        .disabled(!isValid)
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)

                Text("Sending request...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(Color.billixDarkTeal)
            .cornerRadius(20)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.billixDarkTeal)
            Text(title)
                .font(.headline)
                .foregroundColor(.billixDarkTeal)
        }
    }

    private func formatDeadline(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSDecimalNumber(decimal: amount)) ?? "$0.00"
    }

    // MARK: - Actions

    private func submitRequest() async {
        isLoading = true
        defer { isLoading = false }

        let input = ExtensionRequestInput(
            reason: selectedReason,
            customNote: selectedReason == .other ? customNote : nil,
            requestedDeadline: newDeadline,
            partialPaymentAmount: showPartialPayment ? Decimal(string: partialAmount) : nil
        )

        do {
            _ = try await ExtensionService.shared.requestExtension(
                swapId: swapId,
                input: input
            )
            onRequestSent()
            dismiss()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Reason Option Row

private struct ReasonOptionRow: View {
    let reason: ExtensionReason
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .billixGoldenAmber : .gray)

                Image(systemName: reason.icon)
                    .foregroundColor(isSelected ? .billixGoldenAmber : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(reason.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding()
            .background(isSelected ? Color.billixGoldenAmber.opacity(0.1) : Color.billixCreamBeige.opacity(0.5))
            .cornerRadius(12)
        }
    }
}

// MARK: - Duration Pill

private struct DurationPill: View {
    let name: String
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .billixDarkTeal)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? Color.billixDarkTeal : Color.billixCreamBeige)
                .cornerRadius(20)
        }
    }
}

// MARK: - Summary Row

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Extension Response Sheet

struct ExtensionResponseSheet: View {
    @Environment(\.dismiss) private var dismiss

    let request: ExtensionRequest
    let onResponse: (Bool) -> Void

    @State private var isLoading = false
    @State private var denyReason: String = ""
    @State private var showDenyReason = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Request details
                    requestDetails

                    // Response buttons
                    responseButtons
                }
                .padding()
            }
            .background(Color.billixCreamBeige.ignoresSafeArea())
            .navigationTitle("Extension Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showDenyReason) {
                denyReasonSheet
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
        }
    }

    private var requestDetails: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundColor(.billixGoldenAmber)

                Text("Partner Requested Extension")
                    .font(.title3)
                    .fontWeight(.bold)

                if let remaining = request.formattedTimeRemaining {
                    Text(remaining)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            // Details card
            VStack(alignment: .leading, spacing: 12) {
                ExtensionDetailRow(icon: "questionmark.circle", label: "Reason", value: request.reason.displayName)
                ExtensionDetailRow(icon: "calendar", label: "Original", value: formatDate(request.originalDeadline))
                ExtensionDetailRow(icon: "arrow.right.circle", label: "Requested", value: formatDate(request.requestedDeadline))
                ExtensionDetailRow(icon: "clock", label: "Extension", value: request.formattedExtensionDuration)

                if let partial = request.formattedPartialPayment {
                    ExtensionDetailRow(icon: "dollarsign.circle", label: "Partial Payment", value: partial)
                }

                if let note = request.customNote, !note.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Note")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(note)
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
        }
    }

    private var responseButtons: some View {
        VStack(spacing: 12) {
            // Approve button
            Button {
                Task { await approve() }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approve Extension")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.billixMoneyGreen)
                .cornerRadius(16)
            }

            // Deny button
            Button {
                showDenyReason = true
            } label: {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Deny Extension")
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(16)
            }
        }
    }

    private var denyReasonSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Why are you denying this request?")
                    .font(.headline)

                TextEditor(text: $denyReason)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.billixCreamBeige)
                    .cornerRadius(10)

                Button {
                    Task { await deny() }
                } label: {
                    Text("Deny Request")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(16)
                }
            }
            .padding()
            .navigationTitle("Deny Extension")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDenyReason = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func approve() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ExtensionService.shared.approveExtension(requestId: request.id)
            onResponse(true)
            dismiss()
        } catch {
            // Handle error
        }
    }

    private func deny() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ExtensionService.shared.denyExtension(
                requestId: request.id,
                reason: denyReason.isEmpty ? nil : denyReason
            )
            onResponse(false)
            showDenyReason = false
            dismiss()
        } catch {
            // Handle error
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct ExtensionDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.billixDarkTeal)
                .frame(width: 24)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Request Sheet") {
    ExtensionRequestSheet(
        swapId: UUID(),
        currentDeadline: Date().addingTimeInterval(48 * 3600)
    ) {}
}

#Preview("Response Sheet") {
    ExtensionResponseSheet(
        request: ExtensionRequest.mockRequest()
    ) { _ in }
}
#endif
