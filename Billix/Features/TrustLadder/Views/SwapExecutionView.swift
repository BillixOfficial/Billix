//
//  SwapExecutionView.swift
//  Billix
//
//  Created by Claude Code on 12/16/24.
//  Step-by-step view for executing a swap
//

import SwiftUI
import PhotosUI

struct SwapExecutionView: View {
    let swap: Swap
    @Environment(\.dismiss) private var dismiss

    @StateObject private var executionService = SwapExecutionService.shared
    @StateObject private var storeKitService = SwapStoreKitService.shared
    @StateObject private var verificationService = ScreenshotVerificationService.shared

    @State private var currentSwap: Swap
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var screenshotImage: UIImage?
    @State private var showingPhotoPicker = false
    @State private var showingCamera = false
    @State private var showingRatingSheet = false
    @State private var partnerRating = 5
    @State private var showingError = false
    @State private var errorMessage = ""

    // Theme
    private let background = Color(hex: "#F7F9F8")
    private let cardBg = Color.white
    private let primaryText = Color(hex: "#2D3B35")
    private let secondaryText = Color(hex: "#8B9A94")
    private let accent = Color(hex: "#5B8A6B")
    private let warning = Color(hex: "#E8A946")
    private let success = Color(hex: "#4CAF50")
    private let error = Color(hex: "#E57373")

    init(swap: Swap) {
        self.swap = swap
        self._currentSwap = State(initialValue: swap)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Progress indicator
                        progressIndicator
                            .padding(.top, 8)

                        // Status card
                        statusCard

                        // Main content based on status
                        mainContent

                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Swap Execution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }

                if currentSwap.swapStatus == .completed {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Rate Partner") {
                            showingRatingSheet = true
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingRatingSheet) {
                ratingSheet
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhoto,
                matching: .images
            )
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    await loadPhoto(from: newValue)
                }
            }
            .task {
                await refreshSwap()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 0) {
            ForEach(SwapStep.allCases, id: \.self) { step in
                stepIndicator(step)

                if step != SwapStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? accent : secondaryText.opacity(0.3))
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal)
    }

    private func stepIndicator(_ step: SwapStep) -> some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? accent : secondaryText.opacity(0.3))
                    .frame(width: 32, height: 32)

                if step.rawValue < currentStep.rawValue {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(step.rawValue == currentStep.rawValue ? .white : secondaryText)
                }
            }

            Text(step.title)
                .font(.system(size: 10))
                .foregroundColor(step.rawValue <= currentStep.rawValue ? primaryText : secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var currentStep: SwapStep {
        switch currentSwap.swapStatus {
        case .matched, .pending:
            return .payFee
        case .feePending:
            return .payFee
        case .feePaid:
            return .payBill
        case .legAComplete, .legBComplete:
            return .uploadProof
        case .completed:
            return .complete
        case .disputed, .failed, .cancelled, .refunded:
            return .complete
        }
    }

    // MARK: - Status Card

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                statusIcon
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(primaryText)

                    Text(statusSubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(secondaryText)
                }

                Spacer()

                if let deadline = currentSwap.executionDeadline {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Deadline")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryText)

                        Text(deadline, style: .relative)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(currentSwap.isExpired ? error : primaryText)
                    }
                }
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)
        }
    }

    private var statusIcon: Image {
        switch currentSwap.swapStatus {
        case .matched, .pending:
            return Image(systemName: "handshake.fill")
        case .feePending:
            return Image(systemName: "clock.fill")
        case .feePaid:
            return Image(systemName: "creditcard.fill")
        case .legAComplete, .legBComplete:
            return Image(systemName: "arrow.right.arrow.left")
        case .completed:
            return Image(systemName: "checkmark.circle.fill")
        case .disputed:
            return Image(systemName: "exclamationmark.triangle.fill")
        case .failed, .cancelled, .refunded:
            return Image(systemName: "xmark.circle.fill")
        }
    }

    private var statusColor: Color {
        switch currentSwap.swapStatus {
        case .matched, .feePaid:
            return accent
        case .feePending:
            return warning
        case .legAComplete, .legBComplete:
            return accent
        case .completed:
            return success
        case .disputed:
            return warning
        case .failed, .cancelled, .refunded:
            return error
        default:
            return secondaryText
        }
    }

    private var statusTitle: String {
        switch currentSwap.swapStatus {
        case .matched:
            return "Matched!"
        case .feePending:
            return "Awaiting Fee Payment"
        case .feePaid:
            return "Ready to Execute"
        case .legAComplete:
            return isUserA ? "Your Payment Submitted" : "Partner Paid Your Bill"
        case .legBComplete:
            return isUserA ? "Partner Paid Your Bill" : "Your Payment Submitted"
        case .completed:
            return "Swap Complete!"
        case .disputed:
            return "Under Review"
        case .failed:
            return "Swap Failed"
        case .cancelled:
            return "Cancelled"
        case .refunded:
            return "Refunded"
        default:
            return "Processing"
        }
    }

    private var statusSubtitle: String {
        switch currentSwap.swapStatus {
        case .matched:
            return "Pay the coordination fee to proceed"
        case .feePending:
            return waitingForPartnerFee ? "Waiting for your partner's fee" : "Pay the $0.99 fee to continue"
        case .feePaid:
            return "Pay your partner's bill, then upload proof"
        case .legAComplete, .legBComplete:
            return hasUserCompleted ? "Waiting for partner's proof" : "Upload your payment proof"
        case .completed:
            return "Both parties verified. Points awarded!"
        case .disputed:
            return "Our team is reviewing the screenshots"
        case .failed:
            return currentSwap.disputeReason ?? "The swap could not be completed"
        case .cancelled:
            return "This swap was cancelled"
        case .refunded:
            return "Your fee has been refunded"
        default:
            return ""
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        switch currentSwap.swapStatus {
        case .matched, .feePending:
            feePaymentSection

        case .feePaid:
            billPaymentSection

        case .legAComplete, .legBComplete:
            if hasUserCompleted {
                waitingForPartnerSection
            } else {
                proofUploadSection
            }

        case .completed:
            completionSection

        case .disputed:
            disputeSection

        case .failed, .cancelled, .refunded:
            failureSection

        default:
            EmptyView()
        }
    }

    // MARK: - Fee Payment Section

    private var feePaymentSection: some View {
        VStack(spacing: 16) {
            // Partner info
            partnerInfoCard

            // Fee details
            VStack(spacing: 12) {
                Text("Coordination Fee")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)

                Text("$0.99")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(accent)

                Text("This one-time fee secures your swap and enables screenshot verification")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(cardBg)
            .cornerRadius(12)

            // Pay button
            if !hasUserPaidFee {
                Button {
                    Task { await payCoordinationFee() }
                } label: {
                    HStack {
                        if storeKitService.purchaseStatus == .purchasing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Pay $0.99 to Secure Swap")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accent)
                    .cornerRadius(12)
                }
                .disabled(storeKitService.purchaseStatus == .purchasing)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(success)
                    Text("Fee Paid - Waiting for Partner")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(primaryText)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(success.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Bill Payment Section

    private var billPaymentSection: some View {
        VStack(spacing: 16) {
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Pay Your Partner's Bill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(primaryText)

                Text("Pay the amount below directly to your partner's provider using Guest Pay")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Bill details
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Provider")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                        Text(partnerBillProvider)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(primaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Amount")
                            .font(.system(size: 12))
                            .foregroundColor(secondaryText)
                        Text(String(format: "$%.2f", partnerAmount))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(accent)
                    }
                }

                Divider()

                VStack(spacing: 8) {
                    Text("Guest Pay Instructions")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryText)

                    Text("1. Visit the provider's website or app\n2. Look for 'Guest Pay' or 'Quick Pay'\n3. Enter the account holder's phone/email\n4. Complete the payment\n5. Take a screenshot of confirmation")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()
            .background(cardBg)
            .cornerRadius(12)

            // Upload button
            Button {
                showingPhotoPicker = true
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Upload Payment Screenshot")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(accent)
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Proof Upload Section

    private var proofUploadSection: some View {
        VStack(spacing: 16) {
            Text("Upload Payment Proof")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(primaryText)

            if let image = screenshotImage {
                // Show selected image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)

                HStack(spacing: 12) {
                    Button {
                        screenshotImage = nil
                        selectedPhoto = nil
                    } label: {
                        Text("Choose Different")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(accent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(accent.opacity(0.1))
                            .cornerRadius(10)
                    }

                    Button {
                        Task { await submitProof() }
                    } label: {
                        HStack {
                            if verificationService.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Submit Proof")
                            }
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(accent)
                        .cornerRadius(10)
                    }
                    .disabled(verificationService.isProcessing)
                }
            } else {
                // Upload options
                VStack(spacing: 12) {
                    Button {
                        showingPhotoPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Photos")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent.opacity(0.1))
                        .cornerRadius(12)
                    }

                    Button {
                        showingCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera")
                            Text("Take Photo")
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Waiting Section

    private var waitingForPartnerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 48))
                .foregroundColor(warning)

            Text("Waiting for Partner")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Your payment proof has been submitted. We're waiting for your partner to complete their payment.")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            if let deadline = currentSwap.executionDeadline {
                VStack(spacing: 4) {
                    Text("Deadline")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)

                    Text(deadline, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(currentSwap.isExpired ? error : primaryText)
                }
                .padding()
                .background(background)
                .cornerRadius(8)
            }

            // Report ghost button if expired
            if currentSwap.isExpired {
                Button {
                    Task { await reportGhost() }
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("Report Partner as Ghost")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(error)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Completion Section

    private var completionSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(success)

            Text("Swap Complete!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(primaryText)

            Text("Both payments have been verified. You've earned trust points!")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            // Points earned
            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    Text("+\(currentSwap.trustPointsAwarded ?? 50)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(accent)
                    Text("Trust Points")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }

                VStack(spacing: 4) {
                    Text(String(format: "$%.2f", currentSwap.userAAmount))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(primaryText)
                    Text("Saved")
                        .font(.system(size: 12))
                        .foregroundColor(secondaryText)
                }
            }
            .padding()
            .background(background)
            .cornerRadius(12)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(accent)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Dispute Section

    private var disputeSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(warning)

            Text("Under Review")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryText)

            Text("Our team is reviewing the payment screenshots. This usually takes 1-2 business days.")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Text(currentSwap.disputeReason ?? "Screenshot verification issue")
                .font(.system(size: 13))
                .foregroundColor(secondaryText)
                .padding()
                .background(background)
                .cornerRadius(8)
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Failure Section

    private var failureSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(error)

            Text(statusTitle)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(primaryText)

            Text(currentSwap.disputeReason ?? "This swap could not be completed")
                .font(.system(size: 14))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Close")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(secondaryText)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Partner Info Card

    private var partnerInfoCard: some View {
        HStack(spacing: 12) {
            // Partner avatar
            Circle()
                .fill(accent.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(partnerInitials)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accent)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Your Partner")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryText)

                Text(partnerHandle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(primaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("5.0") // Would come from partner data
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(primaryText)
                }

                Text("Verified")
                    .font(.system(size: 11))
                    .foregroundColor(success)
            }
        }
        .padding()
        .background(cardBg)
        .cornerRadius(12)
    }

    // MARK: - Rating Sheet

    private var ratingSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Rate Your Partner")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(primaryText)

                Text("How was your experience with \(partnerHandle)?")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryText)

                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            partnerRating = star
                        } label: {
                            Image(systemName: star <= partnerRating ? "star.fill" : "star")
                                .font(.system(size: 36))
                                .foregroundColor(star <= partnerRating ? .yellow : secondaryText.opacity(0.3))
                        }
                    }
                }

                Button {
                    Task { await submitRating() }
                } label: {
                    Text("Submit Rating")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(accent)
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        showingRatingSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Color(hex: "#F5F7F6"))
    }

    // MARK: - Computed Properties

    private var isUserA: Bool {
        // Would check against current user ID
        return true
    }

    private var hasUserPaidFee: Bool {
        isUserA ? currentSwap.userAFeePaid : currentSwap.userBFeePaid
    }

    private var waitingForPartnerFee: Bool {
        hasUserPaidFee && currentSwap.swapStatus == .feePending
    }

    private var hasUserCompleted: Bool {
        isUserA ? currentSwap.userACompletedAt != nil : currentSwap.userBCompletedAt != nil
    }

    private var partnerHandle: String {
        "@user" // Would fetch from partner data
    }

    private var partnerInitials: String {
        "JD" // Would calculate from partner name
    }

    private var partnerAmount: Double {
        (isUserA ? currentSwap.userBAmount : currentSwap.userAAmount) ?? 0
    }

    private var partnerBillProvider: String {
        "Netflix" // Would fetch from partner's bill data
    }

    // MARK: - Actions

    private func refreshSwap() async {
        do {
            currentSwap = try await executionService.fetchSwap(id: swap.id)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func payCoordinationFee() async {
        do {
            let transactionId = try await storeKitService.purchaseCoordinationFee(for: currentSwap.id)
            currentSwap = try await executionService.recordFeePaid(
                swapId: currentSwap.id,
                transactionId: transactionId
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item = item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                screenshotImage = image
            }
        } catch {
            errorMessage = "Failed to load image"
            showingError = true
        }
    }

    private func submitProof() async {
        guard let image = screenshotImage else { return }

        do {
            let result = try await verificationService.verifyScreenshot(
                image: image,
                expectedAmount: partnerAmount,
                expectedProvider: partnerBillProvider,
                swapId: currentSwap.id
            )

            // Get the uploaded URL from verification service result
            // For now we'll pass the result directly
            currentSwap = try await executionService.submitPaymentProof(
                swapId: currentSwap.id,
                screenshotUrl: "", // URL is handled in verification service
                verificationResult: result
            )

            screenshotImage = nil
            selectedPhoto = nil
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func reportGhost() async {
        do {
            try await executionService.reportGhost(swapId: currentSwap.id)
            await refreshSwap()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func submitRating() async {
        do {
            try await executionService.ratePartner(swapId: currentSwap.id, rating: partnerRating)
            showingRatingSheet = false
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

// MARK: - Swap Step Enum

enum SwapStep: Int, CaseIterable {
    case payFee = 0
    case payBill = 1
    case uploadProof = 2
    case complete = 3

    var title: String {
        switch self {
        case .payFee: return "Fee"
        case .payBill: return "Pay"
        case .uploadProof: return "Proof"
        case .complete: return "Done"
        }
    }
}

// MARK: - Preview

#Preview {
    SwapExecutionView(swap: Swap.mock())
}
