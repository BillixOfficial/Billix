//
//  ClusterBadge.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Badge showing cluster size (👥 X Similar Bills)
//

import SwiftUI

/// Badge displaying the number of similar bills in a cluster
struct ClusterBadge: View {

    // MARK: - Properties

    let count: Int
    let variant: BadgeVariant

    // MARK: - Badge Variant

    enum BadgeVariant {
        case standard
        case compact
        case minimal

        var fontSize: CGFloat {
            switch self {
            case .standard: return 13
            case .compact: return 12
            case .minimal: return 11
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .standard: return 13
            case .compact: return 12
            case .minimal: return 10
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .standard: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .compact: return EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8)
            case .minimal: return EdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
            }
        }
    }

    // MARK: - Initialization

    init(count: Int, variant: BadgeVariant = .standard) {
        self.count = count
        self.variant = variant
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "person.2.fill")
                .font(.system(size: variant.iconSize, weight: .semibold))

            Text("\(count)")
                .font(.system(size: variant.fontSize, weight: .bold))
                .monospacedDigit()
        }
        .foregroundColor(.billixDarkTeal)
        .padding(variant.padding)
        .background(
            Capsule()
                .fill(Color.billixDarkTeal.opacity(0.12))
        )
    }
}

// MARK: - Alternative Variants

/// Cluster badge with custom text
struct ClusterBadgeWithLabel: View {
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 12, weight: .semibold))

            Text("\(count) \(label)")
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(.billixDarkTeal)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.billixDarkTeal.opacity(0.12))
        )
    }
}

/// Minimal cluster indicator (just icon + number)
struct MinimalClusterIndicator: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 10, weight: .medium))

            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
        }
        .foregroundColor(.secondary)
    }
}

// MARK: - Previews

struct ClusterBadge_Cluster_Badge___Variants_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        VStack(alignment: .leading, spacing: 12) {
        Text("Standard Variant")
        .font(.headline)
        
        HStack(spacing: 12) {
        ClusterBadge(count: 5, variant: .standard)
        ClusterBadge(count: 15, variant: .standard)
        ClusterBadge(count: 127, variant: .standard)
        }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("Compact Variant")
        .font(.headline)
        
        HStack(spacing: 12) {
        ClusterBadge(count: 5, variant: .compact)
        ClusterBadge(count: 15, variant: .compact)
        ClusterBadge(count: 127, variant: .compact)
        }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("Minimal Variant")
        .font(.headline)
        
        HStack(spacing: 12) {
        ClusterBadge(count: 5, variant: .minimal)
        ClusterBadge(count: 15, variant: .minimal)
        ClusterBadge(count: 127, variant: .minimal)
        }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("With Labels")
        .font(.headline)
        
        VStack(alignment: .leading, spacing: 8) {
        ClusterBadgeWithLabel(count: 5, label: "Similar Bills")
        ClusterBadgeWithLabel(count: 23, label: "Neighbors")
        ClusterBadgeWithLabel(count: 8, label: "Matches")
        }
        }
        
        Divider()
        
        VStack(alignment: .leading, spacing: 12) {
        Text("Minimal Indicators")
        .font(.headline)
        
        HStack(spacing: 12) {
        MinimalClusterIndicator(count: 5)
        MinimalClusterIndicator(count: 15)
        MinimalClusterIndicator(count: 127)
        }
        }
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}

struct ClusterBadge_Cluster_Badge___In_Card_Context_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        // Simulated bill card header
        VStack(alignment: .leading, spacing: 12) {
        HStack {
        VStack(alignment: .leading, spacing: 4) {
        Text("DTE Energy")
        .font(.headline)
        Text("Electric • Residential")
        .font(.caption)
        .foregroundColor(.secondary)
        }
        
        Spacer()
        
        ClusterBadge(count: 15, variant: .standard)
        }
        
        Divider()
        
        Text("Based on 15 similar bills from your area")
        .font(.caption)
        .foregroundColor(.secondary)
        }
        .padding()
        .background(
        RoundedRectangle(cornerRadius: 16)
        .fill(Color.white)
        .shadow(radius: 4)
        )
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
