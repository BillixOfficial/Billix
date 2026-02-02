//
//  UploadDetailView.swift
//  Billix
//
//  Created by Claude Code on 11/25/25.
//

import SwiftUI

struct UploadDetailView: View {
    let upload: RecentUpload
    let storedBill: StoredBill
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.billixLightGreen
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Content varies by source type
                        if upload.source == .quickAdd {
                            // Show header for Quick Add (no embedded header)
                            headerSection
                            quickAddDetailContent
                        } else {
                            // Scan upload uses embedded view with its own header
                            scanUploadDetailContent
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(upload.provider)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.billixChartBlue)
                }
            }
            .confirmationDialog("Delete this bill?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    deleteBill()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func deleteBill() {
        modelContext.delete(storedBill)
        try? modelContext.save()
        dismiss()
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            // Source badge
            HStack(spacing: 6) {
                if upload.source == .quickAdd {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                }
                Text(upload.source.displayName)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.billixMoneyGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.billixMoneyGreen.opacity(0.1))
            )

            // Amount
            Text(upload.formattedAmount)
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.billixDarkGreen)

            // Date
            Text(upload.formattedDate)
                .font(.system(size: 14))
                .foregroundColor(.billixMediumGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }

    // MARK: - Quick Add Detail Content

    @ViewBuilder
    private var quickAddDetailContent: some View {
        if let result = storedBill.quickAddResult {
            // Comparison Card
            comparisonCard(result: result)

            // Savings Card (if applicable)
            if let savings = result.potentialSavings, savings > 0 {
                savingsCard(savings: savings)
            }

            // Detailed Info Card
            detailInfoCard(result: result)
        }
    }

    private func comparisonCard(result: QuickAddResult) -> some View {
        VStack(spacing: 16) {
            Text("Rate Comparison")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            HStack {
                // Your Bill
                VStack(spacing: 6) {
                    Text("Your Bill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text(String(format: "$%.2f", result.amount))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor(for: result.status))
                }
                .frame(maxWidth: .infinity)

                // VS Divider
                Text("vs")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                // Area Average
                VStack(spacing: 6) {
                    Text("Area Avg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.billixMediumGreen)

                    Text(String(format: "$%.2f", result.areaAverage))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
            }

            // Percent Difference
            Text(String(format: "%.0f%% %@",
                       abs(result.percentDifference),
                       statusSubtitle(for: result.status)))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(statusColor(for: result.status))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }

    private func savingsCard(savings: Double) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(.billixSavingsYellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("Potential Savings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.billixMediumGreen)

                Text(String(format: "$%.2f/month", savings))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.billixSavingsYellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.billixSavingsYellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func detailInfoCard(result: QuickAddResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            DetailRow(label: "Bill Type", value: result.billType.name)
            DetailRow(label: "Provider", value: result.provider.name)
            DetailRow(label: "Frequency", value: result.frequency.displayName)
            DetailRow(label: "Status", value: statusTitle(for: result.status))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }

    // MARK: - Scan Upload Detail Content

    @ViewBuilder
    private var scanUploadDetailContent: some View {
        if let analysis = storedBill.analysis {
            // Use tabbed layout with hero section and swipeable tabs
            AnalysisResultsTabbedEmbeddedView(analysis: analysis)
        }
    }

    private func keyFactsCard(keyFacts: [BillAnalysis.KeyFact]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Facts")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            ForEach(keyFacts, id: \.label) { fact in
                DetailRow(label: fact.label, value: fact.value)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }

    private func basicDetailsCard(analysis: BillAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            DetailRow(label: "Provider", value: analysis.provider)
            DetailRow(label: "Category", value: analysis.category)
            DetailRow(label: "Bill Date", value: analysis.billDate)

            if let dueDate = analysis.dueDate {
                DetailRow(label: "Due Date", value: dueDate)
            }
            if let accountNumber = analysis.accountNumber {
                DetailRow(label: "Account", value: accountNumber)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10)
        )
    }

    // MARK: - Helpers

    private func statusColor(for status: QuickAddResult.Status) -> Color {
        switch status {
        case .overpaying: return .statusOverpaying
        case .underpaying: return .statusUnderpaying
        case .average: return .statusNeutral
        }
    }

    private func statusTitle(for status: QuickAddResult.Status) -> String {
        switch status {
        case .overpaying: return "Paying More"
        case .underpaying: return "Great Deal"
        case .average: return "On Target"
        }
    }

    private func statusSubtitle(for status: QuickAddResult.Status) -> String {
        switch status {
        case .overpaying: return "above Billix average"
        case .underpaying: return "below Billix average"
        case .average: return "close to Billix average"
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.billixMediumGreen)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixDarkGreen)
        }
    }
}

#Preview {
    UploadDetailView(
        upload: RecentUpload(
            id: UUID(),
            provider: "DTE Energy",
            amount: 145.50,
            source: .quickAdd,
            status: .analyzed,
            uploadDate: Date(),
            thumbnailName: nil
        ),
        storedBill: StoredBill(
            uploadDate: Date(),
            quickAddResult: QuickAddResult(
                billType: BillType(id: "electric", name: "Electric", icon: "bolt.fill", category: "Utilities"),
                provider: BillProvider(id: "dte", name: "DTE Energy", category: "utilities", avgAmount: 125.00, sampleSize: 47),
                amount: 145.50,
                frequency: .monthly,
                areaAverage: 125.00,
                percentDifference: 16.4,
                status: .overpaying,
                potentialSavings: 14.35,
                message: "You're paying 16% more than average",
                ctaMessage: nil
            )
        )
    )
}
