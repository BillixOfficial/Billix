//
//  ExternalPaymentView.swift
//  Billix
//
//  Phase 3: External Execution
//  Guides the supporter to pay via the utility company's Guest Pay portal
//  Money NEVER touches Billix - this is our "No-Touch" legal model
//

import SwiftUI

struct ExternalPaymentView: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var hasOpenedPortal = false
    @State private var showProofUpload = false
    @State private var showNoLinkAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Amount Card
                    PaymentAmountCard(viewModel: viewModel)

                    // Steps Card
                    PaymentStepsCard(hasOpenedPortal: hasOpenedPortal)

                    // Open Portal Button
                    OpenPortalButton(
                        viewModel: viewModel,
                        hasOpenedPortal: $hasOpenedPortal,
                        showNoLinkAlert: $showNoLinkAlert
                    )

                    // Upload Proof Button (shows after portal opened)
                    if hasOpenedPortal {
                        UploadProofButton(showProofUpload: $showProofUpload)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Make Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color.billixDarkTeal)
                }
            }
            .alert("No Guest Pay Link", isPresented: $showNoLinkAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This bill doesn't have a Guest Pay link. Please contact the requester for payment information.")
            }
            .sheet(isPresented: $showProofUpload) {
                ProofUploadView(connection: connection, viewModel: viewModel)
            }
        }
    }
}

// MARK: - Payment Amount Card

struct PaymentAmountCard: View {
    @ObservedObject var viewModel: ConnectionDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }

                Text(viewModel.terms?.formattedAmount ?? viewModel.bill?.formattedAmount ?? "$--")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let terms = viewModel.terms {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text("Due \(terms.formattedDeadline)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Provider info
            if let bill = viewModel.bill {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pay to")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text(bill.providerName ?? "Utility Provider")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(Color.billixDarkTeal)
                    }

                    Spacer()

                    if let category = bill.category {
                        HStack(spacing: 4) {
                            Image(systemName: category.icon)
                                .font(.system(size: 12))
                            Text(category.displayName)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(Capsule())
                    }
                }
                .padding(16)
                .background(Color.white)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Payment Steps Card

struct PaymentStepsCard: View {
    let hasOpenedPortal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixDarkTeal)
                Text("How to Complete Payment")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.billixDarkTeal)
            }

            VStack(alignment: .leading, spacing: 14) {
                PaymentStepRow(
                    number: 1,
                    title: "Open the utility portal",
                    subtitle: "Tap the button below to visit their website",
                    isComplete: hasOpenedPortal
                )

                PaymentStepRow(
                    number: 2,
                    title: "Make the payment",
                    subtitle: "Pay using their Guest Pay or Quick Pay option",
                    isComplete: false
                )

                PaymentStepRow(
                    number: 3,
                    title: "Screenshot the confirmation",
                    subtitle: "Capture the page showing payment success",
                    isComplete: false
                )

                PaymentStepRow(
                    number: 4,
                    title: "Upload your proof",
                    subtitle: "Come back here and tap Upload Proof",
                    isComplete: false
                )
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 3)
    }
}

struct PaymentStepRow: View {
    let number: Int
    let title: String
    let subtitle: String
    let isComplete: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(isComplete ? Color.billixMoneyGreen : Color.billixDarkTeal.opacity(0.1))
                    .frame(width: 28, height: 28)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.billixDarkTeal)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isComplete ? Color.billixMoneyGreen : .primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Open Portal Button

struct OpenPortalButton: View {
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var hasOpenedPortal: Bool
    @Binding var showNoLinkAlert: Bool

    var body: some View {
        Button {
            openGuestPayPortal()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: "arrow.up.right.square.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(hasOpenedPortal ? "Open Portal Again" : "Open Utility Portal")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Pay on their secure website")
                        .font(.system(size: 12))
                        .opacity(0.85)
                }
                .foregroundColor(.white)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: hasOpenedPortal ?
                        [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)] :
                        [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(
                color: hasOpenedPortal ? Color.billixMoneyGreen.opacity(0.3) : Color.billixDarkTeal.opacity(0.3),
                radius: 8, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private func openGuestPayPortal() {
        guard let guestPayLink = viewModel.bill?.guestPayLink else {
            showNoLinkAlert = true
            return
        }

        // Add https:// if the URL doesn't have a scheme
        var urlString = guestPayLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.lowercased().hasPrefix("http://") && !urlString.lowercased().hasPrefix("https://") {
            urlString = "https://" + urlString
        }

        guard let url = URL(string: urlString) else {
            showNoLinkAlert = true
            return
        }

        UIApplication.shared.open(url) { success in
            if success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    hasOpenedPortal = true
                }
            }
        }
    }
}

// MARK: - Upload Proof Button

struct UploadProofButton: View {
    @Binding var showProofUpload: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Success indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixMoneyGreen)
                Text("Portal opened - ready to upload proof")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.billixMoneyGreen)
            }

            Button {
                showProofUpload = true
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Upload Payment Proof")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Screenshot of confirmation")
                            .font(.system(size: 12))
                            .opacity(0.85)
                    }
                    .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.billixGoldenAmber, Color.billixGoldenAmber.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.billixGoldenAmber.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}

// MARK: - Standalone View (for navigation)

struct ExternalPaymentStandaloneView: View {
    let connectionId: UUID
    @StateObject private var viewModel: ExternalPaymentStandaloneViewModel

    init(connectionId: UUID) {
        self.connectionId = connectionId
        self._viewModel = StateObject(wrappedValue: ExternalPaymentStandaloneViewModel(connectionId: connectionId))
    }

    var body: some View {
        Group {
            if let connection = viewModel.connection {
                ExternalPaymentView(
                    connection: connection,
                    viewModel: ConnectionDetailViewModel(connection: connection)
                )
            } else if viewModel.isLoading {
                ProgressView("Loading...")
            } else if let error = viewModel.error {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(Color.billixGoldenAmber)
                    Text("Error loading connection")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

@MainActor
class ExternalPaymentStandaloneViewModel: ObservableObject {
    @Published var connection: Connection?
    @Published var isLoading = false
    @Published var error: Error?

    init(connectionId: UUID) {
        Task {
            await loadConnection(id: connectionId)
        }
    }

    func loadConnection(id: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            connection = try await ConnectionService.shared.getConnection(id: id)
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

struct ExternalPaymentView_Previews: PreviewProvider {
    static var previews: some View {
        ExternalPaymentView(
        connection: Connection.mockExecuting(),
        viewModel: ConnectionDetailViewModel(connection: Connection.mockExecuting())
        )
    }
}
