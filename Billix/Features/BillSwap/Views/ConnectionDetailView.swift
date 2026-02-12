//
//  ConnectionDetailView.swift
//  Billix
//
//  Detail view for a Bill Connection showing the 5-phase journey
//  Adapts based on current phase and user's role (initiator vs supporter)
//

import SwiftUI

struct ConnectionDetailView: View {
    let connection: Connection
    @StateObject private var viewModel: ConnectionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCancelAlert = false
    @State private var showDisputeSheet = false
    @State private var showProofUpload = false
    @State private var showTermsProposal = false
    @State private var showExternalPayment = false

    init(connection: Connection) {
        self.connection = connection
        self._viewModel = StateObject(wrappedValue: ConnectionDetailViewModel(connection: connection))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Phase Progress Indicator
                PhaseProgressView(
                    currentPhase: connection.phase,
                    status: connection.status
                )
                .padding(.horizontal)

                // Connection Status Card
                ConnectionStatusCard(
                    connection: connection,
                    viewModel: viewModel
                )

                // Phase-Specific Content
                PhaseContentView(
                    connection: connection,
                    viewModel: viewModel,
                    showProofUpload: $showProofUpload,
                    showTermsProposal: $showTermsProposal,
                    showExternalPayment: $showExternalPayment
                )

                // Action Buttons
                ActionButtonsView(
                    connection: connection,
                    viewModel: viewModel,
                    showCancelAlert: $showCancelAlert,
                    showDisputeSheet: $showDisputeSheet,
                    showProofUpload: $showProofUpload,
                    showTermsProposal: $showTermsProposal,
                    showExternalPayment: $showExternalPayment
                )

                Spacer(minLength: 100)
            }
            .padding(.vertical)
        }
        .background(Color.billixCreamBeige.ignoresSafeArea())
        .navigationTitle("Connection Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if connection.isActive {
                        Button(role: .destructive) {
                            showCancelAlert = true
                        } label: {
                            Label("Cancel Connection", systemImage: "xmark.circle")
                        }

                        Button(role: .destructive) {
                            showDisputeSheet = true
                        } label: {
                            Label("Report Issue", systemImage: "exclamationmark.triangle")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color.billixDarkTeal)
                }
            }
        }
        .alert("Cancel Connection?", isPresented: $showCancelAlert) {
            Button("Keep Connection", role: .cancel) { }
            Button("Cancel", role: .destructive) {
                Task {
                    await viewModel.cancelConnection()
                    dismiss()
                }
            }
        } message: {
            Text("This will end the connection. If payment has already been made, please raise a dispute instead.")
        }
        .sheet(isPresented: $showDisputeSheet) {
            DisputeSheet(connection: connection, viewModel: viewModel)
        }
        .sheet(isPresented: $showProofUpload) {
            ProofUploadView(connection: connection, viewModel: viewModel)
        }
        .sheet(isPresented: $showTermsProposal) {
            TermsProposalView(connection: connection, viewModel: viewModel)
        }
        .sheet(isPresented: $showExternalPayment) {
            ExternalPaymentView(connection: connection, viewModel: viewModel)
        }
        .overlay {
            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
    }
}

// MARK: - Phase Progress View

struct PhaseProgressView: View {
    let currentPhase: Int
    let status: ConnectionStatus

    private let phases = [
        (1, "Request", "doc.text.fill"),
        (2, "Connect", "hand.wave.fill"),
        (3, "Pay", "creditcard.fill"),
        (4, "Verify", "checkmark.shield.fill"),
        (5, "Done", "star.fill")
    ]

    var body: some View {
        VStack(spacing: 20) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen.opacity(0.8), Color.billixMoneyGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: progressWidth(for: geometry.size.width), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 24)

            // Phase nodes
            HStack(spacing: 0) {
                ForEach(phases, id: \.0) { phase, name, icon in
                    ImprovedPhaseNode(
                        phase: phase,
                        name: name,
                        icon: icon,
                        isComplete: phase < currentPhase,
                        isCurrent: phase == currentPhase,
                        isActive: status != .cancelled && status != .disputed
                    )

                    if phase < 5 {
                        Spacer()
                    }
                }
            }

            // Status Badge for cancelled/disputed
            if status == .cancelled || status == .disputed {
                HStack(spacing: 6) {
                    Image(systemName: status == .cancelled ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                    Text(status.displayName)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(status.color)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(status.color.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }

    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        let adjustedPhase = max(1, min(currentPhase, 5))
        let progress = CGFloat(adjustedPhase - 1) / 4.0
        return totalWidth * progress
    }
}

struct ImprovedPhaseNode: View {
    let phase: Int
    let name: String
    let icon: String
    let isComplete: Bool
    let isCurrent: Bool
    let isActive: Bool

    var nodeColor: Color {
        if !isActive { return Color.gray.opacity(0.3) }
        if isComplete { return Color.billixMoneyGreen }
        if isCurrent { return Color.billixGoldenAmber }
        return Color.gray.opacity(0.2)
    }

    var iconColor: Color {
        if !isActive { return .gray }
        if isComplete || isCurrent { return .white }
        return .gray.opacity(0.5)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Outer glow for current
                if isCurrent && isActive {
                    Circle()
                        .fill(Color.billixGoldenAmber.opacity(0.2))
                        .frame(width: 52, height: 52)
                }

                Circle()
                    .fill(nodeColor)
                    .frame(width: 40, height: 40)

                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
            }
            .frame(width: 52, height: 52)

            Text(name)
                .font(.system(size: 11, weight: isCurrent ? .semibold : .medium))
                .foregroundColor(isCurrent ? Color.billixDarkTeal : .secondary)
        }
        .frame(width: 60)
    }
}

// MARK: - Connection Status Card

struct ConnectionStatusCard: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.bill?.category?.icon ?? "doc.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.9))

                        Text(viewModel.bill?.providerName ?? "Bill Details")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Text(viewModel.bill?.formattedAmount ?? "$--")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Connection type badge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)

                        Image(systemName: connection.connectionType == .mutual ? "arrow.left.arrow.right" : "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text(connection.connectionType == .mutual ? "Mutual" : "One-Way")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Participants section
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    ParticipantBadge(
                        label: "Requester",
                        isCurrentUser: viewModel.isInitiator,
                        icon: "person.fill"
                    )

                    // Connection arrow with animation potential
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.billixMoneyGreen.opacity(0.3), lineWidth: 2)
                                .frame(width: 36, height: 36)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color.billixMoneyGreen)
                        }

                        Text("Helping")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    ParticipantBadge(
                        label: "Supporter",
                        isCurrentUser: viewModel.isSupporter,
                        icon: "heart.fill",
                        isEmpty: connection.supporterId == nil
                    )
                }

                // Deadline if terms accepted
                if let terms = viewModel.terms, terms.status == .accepted {
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 16))
                            .foregroundColor(Color.billixGoldenAmber)

                        Text("Payment due: ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        +
                        Text(terms.formattedDeadline)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Color.billixDarkTeal)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.billixGoldenAmber.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(20)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 6)
        .padding(.horizontal)
    }
}

struct ParticipantBadge: View {
    let label: String
    let isCurrentUser: Bool
    let icon: String
    var isEmpty: Bool = false

    private var avatarColor: Color {
        if isEmpty { return Color.gray.opacity(0.15) }
        if isCurrentUser { return Color.billixMoneyGreen }
        return Color.billixDarkTeal
    }

    private var ringColor: Color {
        if isEmpty { return Color.gray.opacity(0.2) }
        if isCurrentUser { return Color.billixMoneyGreen.opacity(0.3) }
        return Color.billixDarkTeal.opacity(0.3)
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                // Outer ring
                Circle()
                    .stroke(ringColor, lineWidth: 3)
                    .frame(width: 58, height: 58)

                // Inner glow for current user
                if isCurrentUser {
                    Circle()
                        .fill(Color.billixMoneyGreen.opacity(0.15))
                        .frame(width: 52, height: 52)
                }

                // Avatar circle
                if isEmpty {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 46, height: 46)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isCurrentUser ?
                                    [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.8)] :
                                    [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                }

                // Icon
                if isEmpty {
                    Image(systemName: "person.fill.questionmark")
                        .font(.system(size: 18))
                        .foregroundColor(.gray.opacity(0.5))
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(spacing: 3) {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)

                if isCurrentUser {
                    HStack(spacing: 3) {
                        Circle()
                            .fill(Color.billixMoneyGreen)
                            .frame(width: 6, height: 6)
                        Text("You")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.billixMoneyGreen)
                    }
                } else if isEmpty {
                    Text("Waiting...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                        .italic()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Phase Content View

struct PhaseContentView: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var showProofUpload: Bool
    @Binding var showTermsProposal: Bool
    @Binding var showExternalPayment: Bool

    var body: some View {
        VStack(spacing: 16) {
            switch connection.status {
            case .requested:
                RequestedPhaseContent(connection: connection, viewModel: viewModel)

            case .handshake:
                HandshakePhaseContent(
                    connection: connection,
                    viewModel: viewModel,
                    showTermsProposal: $showTermsProposal
                )

            case .executing:
                ExecutingPhaseContent(
                    connection: connection,
                    viewModel: viewModel,
                    showExternalPayment: $showExternalPayment
                )

            case .proofing:
                ProofingPhaseContent(
                    connection: connection,
                    viewModel: viewModel,
                    showProofUpload: $showProofUpload
                )

            case .completed:
                CompletedPhaseContent(connection: connection, viewModel: viewModel)

            case .cancelled:
                CancelledContent(connection: connection)

            case .disputed:
                DisputedContent(connection: connection)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Phase Content Components

struct RequestedPhaseContent: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel

    var body: some View {
        InfoCard(
            icon: "clock.fill",
            iconColor: Color.billixGoldenAmber,
            title: "Waiting for Supporter",
            message: viewModel.isInitiator
                ? "Your support request is on the Community Board. Someone will offer to help soon!"
                : "You can offer to support this bill from the Community Board."
        )
    }
}

struct HandshakePhaseContent: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var showTermsProposal: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let terms = viewModel.terms {
                // Show terms status
                TermsCard(terms: terms, viewModel: viewModel)
            } else if viewModel.isSupporter {
                // Supporter needs to propose terms
                InfoCard(
                    icon: "doc.text.fill",
                    iconColor: Color.billixGoldenAmber,
                    title: "Propose Terms",
                    message: "Set the payment deadline and confirm the amount. The initiator will review your terms."
                )

                Button {
                    showTermsProposal = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                        Text("Propose Terms")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.billixDarkTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            } else {
                // Initiator waiting for terms
                InfoCard(
                    icon: "hourglass",
                    iconColor: Color.billixGoldenAmber,
                    title: "Awaiting Terms",
                    message: "Your supporter is preparing the terms. You'll be able to accept or decline once they're ready."
                )
            }
        }
    }
}

struct TermsCard: View {
    let terms: ConnectionTerms
    @ObservedObject var viewModel: ConnectionDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                    Text("Proposed Terms")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 5) {
                    Image(systemName: terms.status.icon)
                        .font(.system(size: 11))
                    Text(terms.status.displayName)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.2))
                .clipShape(Capsule())
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [terms.status.color, terms.status.color.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Content
            VStack(spacing: 14) {
                TermsRow(icon: "dollarsign.circle.fill", label: "Amount", value: terms.formattedAmount, valueWeight: .bold)
                TermsRow(icon: "calendar", label: "Pay by", value: terms.formattedDeadline)
                TermsRow(icon: "camera.fill", label: "Proof type", value: terms.proofRequired.displayName)

                // Time remaining for pending terms
                if terms.status == .proposed, let remaining = terms.formattedTimeRemaining {
                    HStack(spacing: 8) {
                        Image(systemName: terms.isExpiringSoon ? "exclamationmark.circle.fill" : "clock.fill")
                            .font(.system(size: 14))
                        Text("\(remaining) to respond")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(terms.isExpiringSoon ? Color(hex: "#C45C5C") : Color.billixGoldenAmber)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background((terms.isExpiringSoon ? Color(hex: "#C45C5C") : Color.billixGoldenAmber).opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Accept/Reject buttons for initiator
                if terms.status == .proposed && viewModel.isInitiator {
                    HStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.rejectTerms()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Decline")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(Color(hex: "#C45C5C"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "#C45C5C").opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        Button {
                            Task {
                                await viewModel.acceptTerms()
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Accept")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

struct TermsRow: View {
    let icon: String
    let label: String
    let value: String
    var valueWeight: Font.Weight = .medium

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixDarkTeal.opacity(0.7))
                    .frame(width: 20)

                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: valueWeight))
                .foregroundColor(Color.billixDarkTeal)
        }
    }
}

struct ExecutingPhaseContent: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var showExternalPayment: Bool

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isSupporter {
                InfoCard(
                    icon: "creditcard.fill",
                    iconColor: Color.billixMoneyGreen,
                    title: "Time to Pay",
                    message: "Open the utility company's portal and make the payment. Then come back to upload proof."
                )

                Button {
                    showExternalPayment = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 18))
                        Text("Open Payment Portal")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            } else {
                InfoCard(
                    icon: "hourglass",
                    iconColor: Color.billixGoldenAmber,
                    title: "Payment in Progress",
                    message: "Your supporter is making the payment through the utility company's portal. You'll be notified when proof is submitted."
                )
            }
        }
    }
}

struct ProofingPhaseContent: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var showProofUpload: Bool

    var body: some View {
        VStack(spacing: 16) {
            if viewModel.isSupporter {
                if connection.proofUrl != nil {
                    InfoCard(
                        icon: "checkmark.seal.fill",
                        iconColor: Color.billixMoneyGreen,
                        title: "Proof Submitted",
                        message: "Your payment proof has been submitted. Waiting for the initiator to verify."
                    )
                } else {
                    InfoCard(
                        icon: "camera.fill",
                        iconColor: Color.billixGoldenAmber,
                        title: "Upload Proof",
                        message: "Take a screenshot of your payment confirmation and upload it as proof."
                    )

                    Button {
                        showProofUpload = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18))
                            Text("Upload Payment Proof")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
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
                }
            } else {
                // Initiator - verify proof
                if let proofUrl = connection.proofUrl {
                    ProofVerificationCard(proofUrl: proofUrl, viewModel: viewModel)
                } else {
                    InfoCard(
                        icon: "hourglass",
                        iconColor: Color.billixGoldenAmber,
                        title: "Waiting for Proof",
                        message: "Your supporter is uploading payment proof. You'll verify it once submitted."
                    )
                }
            }
        }
    }
}

struct ProofVerificationCard: View {
    let proofUrl: String
    @ObservedObject var viewModel: ConnectionDetailViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.system(size: 16))
                    Text("Payment Proof")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)

                Spacer()

                Text("Review Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color.billixPurple, Color.billixPurple.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Image content
            VStack(spacing: 16) {
                AsyncImage(url: URL(string: proofUrl)) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Loading proof...")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 280)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                    case .failure:
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 200)
                            .overlay {
                                VStack(spacing: 10) {
                                    Image(systemName: "photo.badge.exclamationmark")
                                        .font(.system(size: 36))
                                        .foregroundColor(.gray.opacity(0.5))
                                    Text("Could not load image")
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                    @unknown default:
                        EmptyView()
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        // Dispute flow
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text("Report Issue")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: "#C45C5C"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: "#C45C5C").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task {
                            await viewModel.verifyProof()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                            Text("Verify Payment")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.billixMoneyGreen.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
            }
            .padding(16)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

struct CompletedPhaseContent: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @State private var animateCheckmark = false
    @State private var animatePoints = false

    var body: some View {
        VStack(spacing: 20) {
            // Success celebration card
            VStack(spacing: 16) {
                // Animated success icon
                ZStack {
                    // Outer glow rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.billixMoneyGreen.opacity(0.15 - Double(index) * 0.05), lineWidth: 2)
                            .frame(width: 80 + CGFloat(index * 20), height: 80 + CGFloat(index * 20))
                            .scaleEffect(animateCheckmark ? 1.0 : 0.8)
                            .opacity(animateCheckmark ? 1.0 : 0.0)
                    }

                    // Inner circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: Color.billixMoneyGreen.opacity(0.4), radius: 12, x: 0, y: 4)

                    Image(systemName: "checkmark")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateCheckmark ? 1.0 : 0.5)
                }
                .frame(height: 120)

                Text("Connection Complete!")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.billixDarkTeal)

                Text("You've successfully helped each other. Reputation points awarded!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.billixMoneyGreen.opacity(0.08), Color.billixMoneyGreen.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 1)
            )

            // Points awarded cards
            HStack(spacing: 16) {
                PointsAwardedCard(
                    role: "Requester",
                    points: ReputationService.pointsPerConnection + ReputationService.initiatorBonus,
                    icon: "person.fill",
                    isAnimated: animatePoints
                )

                PointsAwardedCard(
                    role: "Supporter",
                    points: ReputationService.pointsPerConnection + ReputationService.supporterBonus,
                    icon: "heart.fill",
                    isAnimated: animatePoints
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                animateCheckmark = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                animatePoints = true
            }
        }
    }
}

struct PointsAwardedCard: View {
    let role: String
    let points: Int
    let icon: String
    let isAnimated: Bool

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.billixGoldenAmber.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color.billixGoldenAmber)
            }

            Text("+\(points)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.billixMoneyGreen)
                .scaleEffect(isAnimated ? 1.0 : 0.5)
                .opacity(isAnimated ? 1.0 : 0.0)

            Text(role)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            HStack(spacing: 2) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
                Text("Rep Points")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(Color.billixGoldenAmber)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

struct CancelledContent: View {
    let connection: Connection

    var body: some View {
        VStack(spacing: 0) {
            // Header with red gradient
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Connection Cancelled")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(hex: "#C45C5C"), Color(hex: "#C45C5C").opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Reason section
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text("Reason")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Text(connection.cancelReason ?? "This connection was cancelled by one of the participants.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

struct DisputedContent: View {
    let connection: Connection

    var body: some View {
        VStack(spacing: 0) {
            // Header with amber gradient
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 56, height: 56)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                Text("Under Review")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.billixGoldenAmber, Color.billixGoldenAmber.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )

            // Info section
            VStack(spacing: 16) {
                Text("A dispute has been raised for this connection. Our team is actively reviewing the case.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.billixDarkTeal)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(Color.billixGoldenAmber)
                    Text("Typical resolution: 24-48 hours")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.billixGoldenAmber.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon with background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.billixDarkTeal)

                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Action Buttons View

struct ActionButtonsView: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Binding var showCancelAlert: Bool
    @Binding var showDisputeSheet: Bool
    @Binding var showProofUpload: Bool
    @Binding var showTermsProposal: Bool
    @Binding var showExternalPayment: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Chat/Message button (if implemented)
            if connection.isActive && connection.supporterId != nil {
                Button {
                    // Open chat/messages
                } label: {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.billixDarkTeal.opacity(0.15))
                                .frame(width: 36, height: 36)

                            Image(systemName: "message.fill")
                                .font(.system(size: 14))
                                .foregroundColor(Color.billixDarkTeal)
                        }

                        Text("Message Partner")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.billixDarkTeal)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.billixDarkTeal.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.billixDarkTeal, Color.billixDarkTeal.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.billixDarkTeal.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(Color.billixDarkTeal.opacity(0.2), lineWidth: 4)
                        .frame(width: 50, height: 50)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Color.billixDarkTeal, Color.billixMoneyGreen],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }

                Text("Processing...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.billixDarkTeal)
            }
            .padding(36)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
        }
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Dispute Sheet

struct DisputeSheet: View {
    let connection: Connection
    @ObservedObject var viewModel: ConnectionDetailViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedReason: DisputeReason = .fakeScreenshot
    @State private var details: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Reason", selection: $selectedReason) {
                        ForEach(DisputeReason.allCases, id: \.self) { reason in
                            Text(reason.displayName).tag(reason)
                        }
                    }
                } header: {
                    Text("What's the issue?")
                }

                Section {
                    TextEditor(text: $details)
                        .frame(minHeight: 100)
                } header: {
                    Text("Additional Details")
                } footer: {
                    Text("Provide any additional information that might help us resolve this issue.")
                }

                Section {
                    Button {
                        Task {
                            await viewModel.raiseDispute(reason: selectedReason, details: details)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Submit Report")
                                .font(.headline)
                            Spacer()
                        }
                    }
                    .foregroundColor(.white)
                    .listRowBackground(Color(hex: "#C45C5C"))
                }
            }
            .navigationTitle("Report Issue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - View Model

@MainActor
class ConnectionDetailViewModel: ObservableObject {
    @Published var connection: Connection
    @Published var bill: SupportBill?
    @Published var terms: ConnectionTerms?
    @Published var isLoading = false
    @Published var error: Error?

    private var currentUserId: UUID? {
        AuthService.shared.currentUser?.id
    }

    var isInitiator: Bool {
        guard let userId = currentUserId else { return false }
        return connection.isInitiator(userId: userId)
    }

    var isSupporter: Bool {
        guard let userId = currentUserId else { return false }
        return connection.isSupporter(userId: userId)
    }

    init(connection: Connection) {
        self.connection = connection
        Task {
            await loadDetails()
        }
    }

    func loadDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Load latest connection state
            connection = try await ConnectionService.shared.getConnection(id: connection.id)

            // Load bill details
            bill = try await ConnectionService.shared.getBill(id: connection.billId)

            // Load terms if in handshake or later
            if connection.phase >= 2 {
                terms = try await TermsService.shared.getCurrentTerms(for: connection.id)
            }
        } catch {
            self.error = error
        }
    }

    func acceptTerms() async {
        guard let terms = terms else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await ConnectionService.shared.acceptTerms(connectionId: connection.id, termsId: terms.id)
            await loadDetails()
        } catch {
            self.error = error
        }
    }

    func rejectTerms() async {
        guard let terms = terms else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await TermsService.shared.rejectTerms(termsId: terms.id)
            await loadDetails()
        } catch {
            self.error = error
        }
    }

    func submitProof(proofUrl: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            connection = try await ConnectionService.shared.submitProof(connectionId: connection.id, proofUrl: proofUrl)
            await loadDetails()
        } catch {
            self.error = error
        }
    }

    func verifyProof() async {
        isLoading = true
        defer { isLoading = false }

        do {
            connection = try await ConnectionService.shared.verifyProof(connectionId: connection.id)
            await loadDetails()
        } catch {
            self.error = error
        }
    }

    func cancelConnection() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ConnectionService.shared.cancelConnection(connectionId: connection.id)
            await loadDetails()
        } catch {
            self.error = error
        }
    }

    func raiseDispute(reason: DisputeReason, details: String?) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await ConnectionService.shared.raiseDispute(
                connectionId: connection.id,
                reason: reason,
                details: details
            )
            await loadDetails()
        } catch {
            self.error = error
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConnectionDetailView(connection: Connection.mockRequested())
    }
}
