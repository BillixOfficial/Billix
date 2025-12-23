//
//  BillHeatmapView.swift
//  Billix
//
//  Created by Claude Code on 11/27/25.
//

import SwiftUI
import MapKit

/// Bill Heatmap - "Zillow for Bills"
struct BillHeatmapView: View {
    @ObservedObject var viewModel: ExploreViewModel
    @State private var showDealsSheet: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Map background
            mapView

            // Overlay controls
            VStack(spacing: 0) {
                // Top filters
                filterBar
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    .padding(.top, MarketplaceTheme.Spacing.sm)

                Spacer()

                // Legend
                legendOverlay
                    .padding(.horizontal, MarketplaceTheme.Spacing.md)
                    .padding(.bottom, MarketplaceTheme.Spacing.md)
            }

            // Zone info bubble
            if let zone = viewModel.selectedZone {
                zoneInfoBubble(zone)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showDealsSheet) {
            nearbyDealsSheet
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Map View

    @State private var cameraPosition: MapCameraPosition = .automatic

    private func updateCameraPosition() {
        cameraPosition = .region(viewModel.mapRegion)
    }

    private var mapView: some View {
        Map(position: $cameraPosition) {
            ForEach(viewModel.heatmapZones) { zone in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)) {
                    ZoneHexagon(zone: zone, isSelected: viewModel.selectedZone?.id == zone.id)
                        .onTapGesture {
                            withAnimation(MarketplaceTheme.Animation.quick) {
                                viewModel.selectZone(zone)
                            }
                        }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .ignoresSafeArea(edges: .top)
        .onAppear {
            updateCameraPosition()
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: MarketplaceTheme.Spacing.xs) {
                ForEach(BillCategoryType.allCases) { category in
                    categoryFilterChip(category)
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(.ultraThinMaterial)
        )
    }

    private func categoryFilterChip(_ category: BillCategoryType) -> some View {
        let isSelected = viewModel.heatmapCategory == category

        return Button {
            withAnimation(MarketplaceTheme.Animation.quick) {
                viewModel.changeHeatmapCategory(category)
            }
        } label: {
            HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                Image(systemName: category.icon)
                    .font(.system(size: 12))

                Text(category.rawValue)
                    .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : MarketplaceTheme.Colors.textSecondary)
            .padding(.horizontal, MarketplaceTheme.Spacing.sm)
            .padding(.vertical, MarketplaceTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend

    private var legendOverlay: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.xs) {
            Text("Average \(viewModel.heatmapCategory.rawValue) Bill")
                .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

            HStack(spacing: MarketplaceTheme.Spacing.md) {
                legendItem(tier: .low, label: "< $50")
                legendItem(tier: .normal, label: "$50–$75")
                legendItem(tier: .high, label: "$75–$90")
                legendItem(tier: .gouging, label: "> $90")
            }
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                .fill(.ultraThinMaterial)
        )
    }

    private func legendItem(tier: PricingTier, label: String) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xxs) {
            Circle()
                .fill(tier.color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
    }

    // MARK: - Zone Info Bubble

    private func zoneInfoBubble(_ zone: HeatmapZone) -> some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ZIP \(zone.zipCode)")
                        .font(.system(size: MarketplaceTheme.Typography.caption, weight: .medium))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    HStack(spacing: MarketplaceTheme.Spacing.xs) {
                        Text("Avg \(zone.category.rawValue):")
                            .font(.system(size: MarketplaceTheme.Typography.body))
                            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)

                        Text("$\(Int(zone.averagePrice))/mo")
                            .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                            .foregroundStyle(zone.tier.color)
                    }
                }

                Spacer()

                // Close button
                Button {
                    withAnimation(MarketplaceTheme.Animation.quick) {
                        viewModel.selectedZone = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            // Status message
            statusMessage(for: zone)

            // Action button
            Button {
                showDealsSheet = true
            } label: {
                HStack {
                    Spacer()
                    Text(zone.tier == .low || zone.tier == .normal ? "Show How They Did It" : "See Nearby Deals")
                        .font(.system(size: MarketplaceTheme.Typography.callout, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, MarketplaceTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.md)
                        .fill(MarketplaceTheme.Colors.primary)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(MarketplaceTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.xl)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .shadow(
                    color: MarketplaceTheme.Shadows.high.color,
                    radius: MarketplaceTheme.Shadows.high.radius,
                    x: 0,
                    y: -MarketplaceTheme.Shadows.high.y
                )
        )
        .padding(.horizontal, MarketplaceTheme.Spacing.md)
        .padding(.bottom, MarketplaceTheme.Spacing.md)
    }

    private func statusMessage(for zone: HeatmapZone) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.xs) {
            Image(systemName: zone.tier == .gouging ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(zone.tier.color)

            Group {
                switch zone.tier {
                case .gouging:
                    Text("You are in a **Price Gouging Pocket**. Nearby avg: $\(Int(zone.marketAverage)).")
                case .high:
                    Text("Above market average. **\(zone.nearbyDealsCount) deals** nearby.")
                case .normal:
                    Text("Near market average. \(zone.residentCount) residents here.")
                case .low:
                    Text("**\(zone.residentCount) residents** are paying less than $\(Int(zone.averagePrice)) here.")
                }
            }
            .font(.system(size: MarketplaceTheme.Typography.caption))
            .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.sm)
                .fill(zone.tier.color.opacity(0.1))
        )
    }

    // MARK: - Nearby Deals Sheet

    private var nearbyDealsSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MarketplaceTheme.Spacing.sm) {
                    ForEach(viewModel.nearbyDeals) { deal in
                        nearbyDealCard(deal)
                    }
                }
                .padding(MarketplaceTheme.Spacing.md)
            }
            .navigationTitle("Nearby Deals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showDealsSheet = false
                    }
                }
            }
        }
    }

    private func nearbyDealCard(_ deal: HeatmapDeal) -> some View {
        HStack(spacing: MarketplaceTheme.Spacing.sm) {
            // Provider icon
            ZStack {
                Circle()
                    .fill(MarketplaceTheme.Colors.primary.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: "wifi")
                    .font(.system(size: 18))
                    .foregroundStyle(MarketplaceTheme.Colors.primary)
            }

            // Deal info
            VStack(alignment: .leading, spacing: 2) {
                Text(deal.providerName)
                    .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                    .foregroundStyle(MarketplaceTheme.Colors.textPrimary)

                HStack(spacing: MarketplaceTheme.Spacing.xs) {
                    Text(deal.zipCode)
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text("•")
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Text(String(format: "%.1f mi away", deal.distance))
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            Spacer()

            // Price and grade
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "$%.2f", deal.price))
                    .font(.system(size: MarketplaceTheme.Typography.headline, weight: .bold))
                    .foregroundStyle(MarketplaceTheme.Colors.success)

                Text(deal.grade)
                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(deal.grade == "S-Tier" ? Color(hex: "#FFD700") : MarketplaceTheme.Colors.success)
                    )
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
        }
        .padding(MarketplaceTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: MarketplaceTheme.Radius.lg)
                .fill(MarketplaceTheme.Colors.backgroundCard)
                .shadow(
                    color: MarketplaceTheme.Shadows.low.color,
                    radius: MarketplaceTheme.Shadows.low.radius,
                    x: 0,
                    y: MarketplaceTheme.Shadows.low.y
                )
        )
    }
}

// MARK: - Zone Hexagon

struct ZoneHexagon: View {
    let zone: HeatmapZone
    let isSelected: Bool

    var body: some View {
        ZStack {
            // Hexagon shape
            Hexagon()
                .fill(zone.tier.color.opacity(isSelected ? 0.8 : 0.5))
                .frame(width: 50, height: 50)

            Hexagon()
                .stroke(isSelected ? .white : zone.tier.color, lineWidth: isSelected ? 3 : 1)
                .frame(width: 50, height: 50)

            // Price label
            Text("$\(Int(zone.averagePrice))")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white)
        }
        .shadow(color: zone.tier.color.opacity(0.5), radius: isSelected ? 8 : 4)
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(MarketplaceTheme.Animation.bouncy, value: isSelected)
    }
}

// MARK: - Hexagon Shape

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2

        for i in 0..<6 {
            let angle = CGFloat(i) * .pi / 3 - .pi / 6
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    BillHeatmapView(viewModel: ExploreViewModel())
}
