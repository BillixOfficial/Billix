//
//  OfferServiceSheet.swift
//  Billix
//
//  Sheet for offering bill negotiation services
//

import SwiftUI

struct OfferServiceSheet: View {
    @ObservedObject var viewModel: MarketplaceViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var serviceTitle = ""
    @State private var serviceDescription = ""
    @State private var selectedCategories: Set<String> = []
    @State private var hourlyRate = ""
    @State private var successFee = ""
    @State private var estimatedSavings = ""

    private let categories = ["Internet", "Mobile", "Energy", "Insurance", "Medical Bills", "Subscriptions"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MarketplaceTheme.Spacing.sm) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(MarketplaceTheme.Colors.primary)

                        Text("Offer Your Service")
                            .font(.system(size: MarketplaceTheme.Typography.title2, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                        Text("Help others negotiate their bills and earn money")
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MarketplaceTheme.Spacing.lg)

                    // Form
                    VStack(spacing: MarketplaceTheme.Spacing.md) {
                        // Service Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Service Title")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("e.g., Expert Cable Bill Negotiator", text: $serviceTitle)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }

                        // Categories
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Categories You Handle")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            FlowLayout(spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    Button {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    } label: {
                                        HStack(spacing: 4) {
                                            if selectedCategories.contains(category) {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                            }
                                            Text(category)
                                        }
                                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                                        .foregroundStyle(selectedCategories.contains(category) ? .white : MarketplaceTheme.Colors.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .fill(selectedCategories.contains(category) ? MarketplaceTheme.Colors.primary : MarketplaceTheme.Colors.backgroundSecondary)
                                        )
                                    }
                                }
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            TextField("Describe your experience and approach...", text: $serviceDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(4...6)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                        .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                )
                        }

                        // Pricing
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pricing")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            HStack(spacing: MarketplaceTheme.Spacing.md) {
                                // Hourly Rate
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Hourly Rate")
                                        .font(.system(size: MarketplaceTheme.Typography.micro))
                                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                                    HStack {
                                        Text("$")
                                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                                        TextField("0", text: $hourlyRate)
                                            .keyboardType(.decimalPad)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                    )
                                }

                                // Success Fee
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Success Fee %")
                                        .font(.system(size: MarketplaceTheme.Typography.micro))
                                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                                    HStack {
                                        TextField("0", text: $successFee)
                                            .keyboardType(.decimalPad)
                                        Text("%")
                                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                            .fill(MarketplaceTheme.Colors.backgroundSecondary)
                                    )
                                }
                            }
                        }

                        // Estimated Savings
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Typical Savings You Achieve")
                                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                            HStack {
                                Text("$")
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                                TextField("e.g., 50-200", text: $estimatedSavings)
                                Text("/month")
                                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                                    .fill(MarketplaceTheme.Colors.backgroundSecondary)
                            )
                        }
                    }
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)

                    Spacer(minLength: MarketplaceTheme.Spacing.xl)

                    // Submit Button
                    Button {
                        // TODO: Submit service offering
                        dismiss()
                    } label: {
                        Text("List My Service")
                            .font(.system(size: MarketplaceTheme.Typography.body, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MarketplaceTheme.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                                    .fill(MarketplaceTheme.Colors.primary)
                            )
                    }
                    .disabled(serviceTitle.isEmpty || selectedCategories.isEmpty)
                    .opacity(serviceTitle.isEmpty || selectedCategories.isEmpty ? 0.5 : 1)
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                }
            }
            .background(MarketplaceTheme.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Flow Layout Helper

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, row) in result.rows.enumerated() {
            for (subviewIndex, subview) in row.enumerated() {
                let x = result.xOffsets[index][subviewIndex] + bounds.minX
                let y = result.yOffsets[index] + bounds.minY
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            }
        }
    }

    struct FlowResult {
        var rows: [[LayoutSubviews.Element]] = []
        var xOffsets: [[CGFloat]] = []
        var yOffsets: [CGFloat] = []
        var height: CGFloat = 0

        init(in width: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var currentRow: [LayoutSubviews.Element] = []
            var currentRowXOffsets: [CGFloat] = []
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if currentX + size.width > width && !currentRow.isEmpty {
                    rows.append(currentRow)
                    xOffsets.append(currentRowXOffsets)
                    yOffsets.append(currentY)
                    currentY += maxHeight + spacing
                    currentRow = []
                    currentRowXOffsets = []
                    currentX = 0
                    maxHeight = 0
                }
                currentRow.append(subview)
                currentRowXOffsets.append(currentX)
                currentX += size.width + spacing
                maxHeight = max(maxHeight, size.height)
            }

            if !currentRow.isEmpty {
                rows.append(currentRow)
                xOffsets.append(currentRowXOffsets)
                yOffsets.append(currentY)
                height = currentY + maxHeight
            }
        }
    }
}
