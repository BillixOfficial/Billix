//
//  MutualMatchesView.swift
//  Billix
//
//  View for finding and selecting mutual swap partners
//  Shows potential matches with compatibility scores
//

import SwiftUI

struct MutualMatchesView: View {
    let myConnection: Connection
    let myBill: SupportBill

    @Environment(\.dismiss) private var dismiss
    @StateObject private var matchService = MutualMatchService.shared
    @State private var selectedMatch: PotentialMutualMatch?
    @State private var showConfirmation = false
    @State private var isMatching = false
    @State private var matchError: String?
    @State private var matchSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if matchService.isLoading && matchService.potentialMatches.isEmpty {
                    loadingView
                } else if matchService.potentialMatches.isEmpty {
                    emptyStateView
                } else {
                    matchesListView
                }
            }
            .navigationTitle("Find a Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            try? await matchService.findMutualMatches(for: myConnection.id, myBill: myBill)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(matchService.isLoading)
                }
            }
            .task {
                try? await matchService.findMutualMatches(for: myConnection.id, myBill: myBill)
            }
            .alert("Confirm Match", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Match") {
                    Task {
                        await confirmMatch()
                    }
                }
            } message: {
                if let match = selectedMatch {
                    Text("Match with this user? Both of you will help each other pay bills. If either side fails, both connections will be cancelled.")
                }
            }
            .alert("Match Created!", isPresented: $matchSuccess) {
                Button("Great!") {
                    dismiss()
                }
            } message: {
                Text("You've been matched! Check your Active Connections to see both connections and start chatting with your partner.")
            }
            .alert("Error", isPresented: .constant(matchError != nil)) {
                Button("OK") {
                    matchError = nil
                }
            } message: {
                Text(matchError ?? "")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)

            Text("Finding mutual partners...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Mutual Partners Found")
                .font(.title3)
                .fontWeight(.semibold)

            Text("There are no other mutual requests available right now. Check back later or wait for someone to post a matching request.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task {
                    try? await matchService.findMutualMatches(for: myConnection.id, myBill: myBill)
                }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(Color.billixDarkTeal)
        }
        .padding()
    }

    // MARK: - Matches List

    private var matchesListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Explanation header
                VStack(alignment: .leading, spacing: 8) {
                    Label("How Mutual Matching Works", systemImage: "info.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.billixDarkTeal)

                    Text("Select a partner below. When you match, BOTH connections are created:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("You help them")
                                .font(.caption.weight(.medium))
                            Text("Pay their bill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Image(systemName: "arrow.left.arrow.right")
                            .font(.caption)
                            .foregroundStyle(Color.billixDarkTeal)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("They help you")
                                .font(.caption.weight(.medium))
                            Text("Pay your bill")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(Color.billixDarkTeal.opacity(0.08))
                .cornerRadius(12)

                // Matches
                ForEach(matchService.potentialMatches) { match in
                    MutualMatchCard(match: match) {
                        selectedMatch = match
                        showConfirmation = true
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Confirm Match

    private func confirmMatch() async {
        guard let match = selectedMatch else { return }

        isMatching = true

        do {
            let pair = try await matchService.acceptMutualMatch(
                myConnectionId: myConnection.id,
                theirConnectionId: match.connection.id
            )

            // Success!
            matchSuccess = true

            // Notify ConnectionService to refresh
            try? await ConnectionService.shared.fetchMyConnections()

        } catch {
            matchError = error.localizedDescription
        }

        isMatching = false
    }
}

// MARK: - Mutual Match Card

struct MutualMatchCard: View {
    let match: PotentialMutualMatch
    let onMatch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with compatibility
            HStack {
                // Bill icon
                ZStack {
                    Circle()
                        .fill((match.bill.category?.color ?? .gray).opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: match.bill.category?.icon ?? "doc.text.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(match.bill.category?.color ?? .gray)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(match.bill.category?.displayName ?? "Bill")
                        .font(.subheadline.weight(.semibold))

                    Text(match.bill.formattedAmount)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color.billixMoneyGreen)
                }

                Spacer()

                // Compatibility badge
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(match.compatibilityScore)%")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Color(hex: match.compatibilityLevel.color))

                    Text(match.compatibilityLevel.displayText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Match reasons
            if !match.matchReasons.isEmpty {
                MatchReasonsFlowLayout(spacing: 6) {
                    ForEach(match.matchReasons, id: \.self) { reason in
                        Text(reason)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(Color.billixDarkTeal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.billixDarkTeal.opacity(0.1))
                            .cornerRadius(6)
                    }
                }
            }

            Divider()

            // Bill details
            HStack(spacing: 16) {
                if let provider = match.bill.providerName {
                    Label(provider, systemImage: "building.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if (match.bill.daysUntilDue ?? 30) <= 7 {
                    Label("Due soon", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.orange)
                } else {
                    Label("Due in \(match.bill.daysUntilDue ?? 30) days", systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Match button
            Button(action: onMatch) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                    Text("Match with this User")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.billixDarkTeal)
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

// MARK: - Match Reasons Flow Layout

struct MatchReasonsFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if rowWidth + size.width + spacing > containerWidth {
                height += rowHeight + spacing
                rowWidth = size.width + spacing
                rowHeight = size.height
            } else {
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        height += rowHeight

        return CGSize(width: containerWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Preview

struct MutualMatchesView_Previews: PreviewProvider {
    static var previews: some View {
        MutualMatchesView(
        myConnection: Connection.mockRequested(),
        myBill: SupportBill.mockElectric()
        )
    }
}
