//
//  MutualPairStatusCard.swift
//  Billix
//
//  Shows the linked partner connection status for mutual swaps
//  Displays progress of both sides of the mutual swap
//

import SwiftUI

struct MutualPairStatusCard: View {
    let pairId: UUID
    let currentConnectionId: UUID

    @State private var pairedConnection: Connection?
    @State private var pairedBill: SupportBill?
    @State private var pairedTermsAccepted: Bool = false
    @State private var isLoading = true
    @State private var showPartnerDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.billixDarkTeal)

                Text("Mutual Swap Partner")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if let paired = pairedConnection {
                // Partner connection status
                HStack(spacing: 12) {
                    // Status icon
                    ZStack {
                        Circle()
                            .fill(paired.status.color.opacity(0.15))
                            .frame(width: 40, height: 40)

                        Image(systemName: paired.status.iconName)
                            .font(.system(size: 16))
                            .foregroundStyle(paired.status.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        if let bill = pairedBill {
                            Text(bill.category?.displayName ?? "Bill")
                                .font(.subheadline.weight(.medium))

                            Text(bill.formattedAmount)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Text(paired.status.displayName)
                            .font(.caption)
                            .foregroundStyle(paired.status.color)
                    }

                    Spacer()

                    // Phase progress
                    if let phase = paired.status.phaseNumber {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Phase \(phase)/5")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)

                            ProgressView(value: paired.progressPercentage)
                                .tint(paired.status.color)
                                .frame(width: 60)
                        }
                    }
                }

                // Partner terms acceptance status (for handshake phase)
                if paired.status == .handshake {
                    HStack(spacing: 8) {
                        Image(systemName: pairedTermsAccepted ? "checkmark.circle.fill" : "clock.fill")
                            .foregroundStyle(pairedTermsAccepted ? Color.billixMoneyGreen : Color.billixGoldenAmber)

                        Text(pairedTermsAccepted ? "Terms Accepted" : "Awaiting Terms Acceptance")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(pairedTermsAccepted ? Color.billixMoneyGreen : .secondary)
                    }
                    .padding(10)
                    .background(pairedTermsAccepted ? Color.billixMoneyGreen.opacity(0.1) : Color.billixGoldenAmber.opacity(0.1))
                    .cornerRadius(8)
                }

                // Warning if partner connection has issues
                if paired.status == .disputed {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)

                        Text("Partner's connection is under dispute. This may affect your connection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                } else if paired.status == .cancelled {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)

                        Text("Partner's connection was cancelled. Your connection has also been cancelled.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(10)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                // View partner button
                Button {
                    showPartnerDetail = true
                } label: {
                    HStack {
                        Text("View Partner's Progress")
                            .font(.caption.weight(.medium))

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                    }
                    .foregroundStyle(Color.billixDarkTeal)
                }
            } else if !isLoading {
                // No paired connection found
                Text("Unable to load partner connection")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .task {
            await loadPairedConnection()
        }
        .sheet(isPresented: $showPartnerDetail) {
            if let paired = pairedConnection, let bill = pairedBill {
                MutualPartnerDetailView(connection: paired, bill: bill)
            }
        }
    }

    private func loadPairedConnection() async {
        isLoading = true

        do {
            pairedConnection = try await MutualMatchService.shared.getPairedConnection(for: currentConnectionId)

            if let paired = pairedConnection {
                pairedBill = try await ConnectionService.shared.getBill(id: paired.billId)

                // Load partner's terms status
                if let terms = try await TermsService.shared.getCurrentTerms(for: paired.id) {
                    pairedTermsAccepted = terms.status == .accepted
                }
            }
        } catch {
            print("Failed to load paired connection: \(error)")
        }

        isLoading = false
    }
}

// MARK: - Mutual Partner Detail View

struct MutualPartnerDetailView: View {
    let connection: Connection
    let bill: SupportBill

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Bill info
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill((bill.category?.color ?? .gray).opacity(0.15))
                                    .frame(width: 50, height: 50)

                                Image(systemName: bill.category?.icon ?? "doc.text.fill")
                                    .font(.title3)
                                    .foregroundStyle(bill.category?.color ?? .gray)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(bill.category?.displayName ?? "Bill")
                                    .font(.headline)

                                if let provider = bill.providerName {
                                    Text(provider)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()

                            Text(bill.formattedAmount)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Color.billixMoneyGreen)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // Connection status
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Connection Progress")
                            .font(.headline)

                        // Phase timeline
                        ForEach(1...5, id: \.self) { phase in
                            HStack(spacing: 12) {
                                // Phase indicator
                                ZStack {
                                    Circle()
                                        .fill(phaseColor(phase))
                                        .frame(width: 32, height: 32)

                                    if connection.phase > phase {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(.white)
                                    } else {
                                        Text("\(phase)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(connection.phase >= phase ? .white : .secondary)
                                    }
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(phaseName(phase))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(connection.phase >= phase ? .primary : .secondary)

                                    Text(phaseDescription(phase))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }

                            if phase < 5 {
                                HStack {
                                    Rectangle()
                                        .fill(connection.phase > phase ? Color.billixMoneyGreen : Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 20)
                                        .padding(.leading, 15)

                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(16)

                    // Note about mutual dependency
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Color.billixDarkTeal)

                        Text("This is your partner's side of the mutual swap. Both connections must complete for full reputation rewards.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.billixDarkTeal.opacity(0.08))
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Partner's Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func phaseColor(_ phase: Int) -> Color {
        if connection.phase > phase {
            return Color.billixMoneyGreen
        } else if connection.phase == phase {
            return connection.status.color
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private func phaseName(_ phase: Int) -> String {
        switch phase {
        case 1: return "Requested"
        case 2: return "Handshake"
        case 3: return "Payment"
        case 4: return "Verification"
        case 5: return "Completed"
        default: return ""
        }
    }

    private func phaseDescription(_ phase: Int) -> String {
        switch phase {
        case 1: return "Bill posted for support"
        case 2: return "Agreeing on terms"
        case 3: return "Paying via utility portal"
        case 4: return "Verifying payment proof"
        case 5: return "Successfully completed"
        default: return ""
        }
    }
}

// MARK: - Preview

struct MutualPairStatusCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
        MutualPairStatusCard(
        pairId: UUID(),
        currentConnectionId: UUID()
        )
        }
        .padding()
        .background(Color(UIColor.systemGroupedBackground))
    }
}
