//
//  ServiceCard.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//

import SwiftUI

/// Card for bill audit, roast, and gig services
struct ServiceCard: View {
    let service: ServiceListing
    let onRequest: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: MarketplaceTheme.Spacing.sm) {
            // Header
            HStack(alignment: .top) {
                // Service type icon
                ZStack {
                    Circle()
                        .fill(serviceColor.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: service.serviceType.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(serviceColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    // Title
                    Text(service.title)
                        .font(.system(size: MarketplaceTheme.Typography.body, weight: .semibold))
                        .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                        .lineLimit(2)

                    // Provider
                    HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 12))
                        Text(service.providerHandle)
                            .font(.system(size: MarketplaceTheme.Typography.caption))

                        if service.isVerifiedHighSaver {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 10))
                                Text("High Saver")
                                    .font(.system(size: MarketplaceTheme.Typography.micro, weight: .medium))
                            }
                            .foregroundStyle(MarketplaceTheme.Colors.success)
                        }
                    }
                    .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                }

                Spacer()

                // Rating
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.billixStarGold)
                        Text(String(format: "%.1f", service.rating))
                            .font(.system(size: MarketplaceTheme.Typography.callout, weight: .bold))
                            .foregroundStyle(MarketplaceTheme.Colors.textPrimary)
                    }
                    Text("(\(service.reviewCount))")
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)
                }
            }

            // Description
            Text(service.description)
                .font(.system(size: MarketplaceTheme.Typography.caption))
                .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                .lineLimit(2)

            // Categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: MarketplaceTheme.Spacing.xxs) {
                    ForEach(service.categories, id: \.self) { category in
                        HStack(spacing: 2) {
                            Image(systemName: category.icon)
                                .font(.system(size: 10))
                            Text(category.rawValue)
                        }
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textSecondary)
                        .padding(.horizontal, MarketplaceTheme.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(MarketplaceTheme.Colors.backgroundSecondary)
                        )
                    }
                }
            }

            Divider()
                .background(MarketplaceTheme.Colors.textTertiary.opacity(0.2))

            // Footer
            HStack {
                // Stats
                HStack(spacing: MarketplaceTheme.Spacing.md) {
                    HStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(MarketplaceTheme.Colors.success)
                        Text("\(service.completedJobs) jobs")
                    }

                    HStack(spacing: 2) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(service.responseTime)
                    }
                }
                .font(.system(size: MarketplaceTheme.Typography.micro))
                .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                Spacer()

                // Compensation + Request
                VStack(alignment: .trailing, spacing: 2) {
                    Text(compensationText)
                        .font(.system(size: MarketplaceTheme.Typography.micro))
                        .foregroundStyle(MarketplaceTheme.Colors.textTertiary)

                    Button(action: onRequest) {
                        Text("Request")
                            .font(.system(size: MarketplaceTheme.Typography.caption, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, MarketplaceTheme.Spacing.md)
                            .padding(.vertical, MarketplaceTheme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(serviceColor)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(MarketplaceTheme.Spacing.md)
        .marketplaceCard(elevation: .low)
    }

    private var serviceColor: Color {
        switch service.serviceType {
        case .billAudit: return MarketplaceTheme.Colors.info
        case .negotiation: return MarketplaceTheme.Colors.primary
        case .billRoast: return MarketplaceTheme.Colors.danger
        case .consultation: return MarketplaceTheme.Colors.secondary
        case .switching: return MarketplaceTheme.Colors.accent
        }
    }

    private var compensationText: String {
        switch service.compensation {
        case .tips:
            if let amount = service.suggestedAmount {
                return "Tips (~\(amount) pts)"
            }
            return "Tips"
        case .fixed:
            if let amount = service.suggestedAmount {
                return "\(amount) pts"
            }
            return "Fixed"
        case .percentage:
            return "% of savings"
        case .free:
            return "Free"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        ForEach(MockMarketplaceData.services) { service in
            ServiceCard(service: service, onRequest: {})
        }
    }
    .padding()
    .background(MarketplaceTheme.Colors.backgroundPrimary)
}
