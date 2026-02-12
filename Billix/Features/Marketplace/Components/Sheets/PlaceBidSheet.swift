//
//  PlaceBidSheet.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Sheet for placing a bid to join a cluster
struct PlaceBidSheet: View {
    let cluster: Cluster
    @Environment(\.dismiss) private var dismiss

    @State private var maxPrice: Double = 75
    @State private var contractEndDate: Date = Date().addingTimeInterval(180 * 24 * 3600) // 6 months
    @State private var willingToSwitch: Bool = true
    @State private var needsInstall: Bool = false
    @State private var zipCode: String = "07030"

    @State private var isSubmitting: Bool = false
    @State private var submitSuccess: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    if submitSuccess {
                        successView
                    } else {
                        // Cluster info
                        clusterInfo

                        Divider()

                        // Bid form
                        bidForm

                        // Privacy note
                        privacyNote
                    }
                }
                .padding(MarketplaceTheme.Spacing.lg)
            }
            .navigationTitle("Place Bid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                if !submitSuccess {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            submitBid()
                        } label: {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                        .disabled(isSubmitting)
                    }
                }
            }
        }
    }

    private var clusterInfo: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Cluster header
            HStack {
                Image(systemName: cluster.type.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(MarketplaceTheme.Colors.secondary)

                Text(cluster.title)
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
            }

            // Progress
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xxs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(MarketplaceTheme.Colors.primary)
                            .frame(width: geo.size.width * cluster.progressPercent, height: 8)
                    }
                }
                .frame(height: 8)

                Text("\(cluster.currentCount) / \(cluster.goalCount) bids")
                    .font(.system(size: MarketplaceTheme.Typography.caption))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }

            // Stats
            if let median = cluster.medianWillingToPay {
                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    Text("Median bid: $\(Int(median))/mo")
                        .font(.system(size: MarketplaceTheme.Typography.caption))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundSecondary)
        )
    }

    private var bidForm: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.lg) {
            // Max price slider
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                HStack {
                    Text("Maximum price I'll pay")
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                    Spacer()

                    Text("$\(Int(maxPrice))/mo")
                        .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                        .foregroundStyle(MarketplaceTheme.Colors.primary)
                }

                Slider(value: $maxPrice, in: 20...200, step: 5)
                    .tint(MarketplaceTheme.Colors.primary)

                HStack {
                    Text("$20")
                    Spacer()
                    Text("$200")
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            }

            // Contract end date
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                Text("My current contract ends")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                DatePicker("", selection: $contractEndDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
            }

            // ZIP code
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
                Text("ZIP Code")
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                TextField("Enter ZIP", text: $zipCode)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            // Toggles
            VStack(spacing: MarketplaceTheme.Spacing.sm) {
                Toggle(isOn: $willingToSwitch) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Willing to switch providers")
                            .font(.system(size: MarketplaceTheme.Typography.callout))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        Text("I'm open to changing to a different provider")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }
                .tint(MarketplaceTheme.Colors.primary)

                Toggle(isOn: $needsInstall) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Need installation")
                            .font(.system(size: MarketplaceTheme.Typography.callout))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        Text("I'll need professional installation")
                            .font(.system(size: MarketplaceTheme.Typography.micro))
                            .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                    }
                }
                .tint(MarketplaceTheme.Colors.primary)
            }
        }
    }

    private var privacyNote: some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(MarketplaceTheme.Colors.info)

            VStack(alignment: .leading, spacing: 0) {
                Text("Your data is anonymized")
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                Text("Only aggregated stats are shared with providers")
                    .font(.system(size: MarketplaceTheme.Typography.micro))
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(MarketplaceTheme.Colors.info.opacity(0.1))
        )
    }

    private var successView: some View {
        VStack(spacing: MarketplaceTheme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(MarketplaceTheme.Colors.success)

            Text("Bid Placed!")
                .font(.system(size: MarketplaceTheme.Typography.title, weight: .bold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            Text("You've joined the cluster. We'll notify you when the goal is reached or a flash drop becomes available.")
                .font(.system(size: MarketplaceTheme.Typography.body))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)

            // Bid summary
            VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
                summaryRow(label: "Max price:", value: "$\(Int(maxPrice))/mo")
                summaryRow(label: "ZIP code:", value: zipCode)
                summaryRow(label: "Willing to switch:", value: willingToSwitch ? "Yes" : "No")
            }
            .padding(MarketplaceTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
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

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
        }
        .font(.system(size: MarketplaceTheme.Typography.caption))
    }

    private func submitBid() {
        isSubmitting = true

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                isSubmitting = false
                withAnimation {
                    submitSuccess = true
                }
            }
        }
    }
}

struct PlaceBidSheet_Previews: PreviewProvider {
    static var previews: some View {
        PlaceBidSheet(cluster: MockMarketplaceData.clusters[0])
    }
}
