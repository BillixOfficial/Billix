//
//  ClustersZone.swift
//  Billix
//

import SwiftUI

// MARK: - Cluster Item Model

struct ClusterItem: Identifiable {
    let id = UUID()
    let category: String
    let icon: String
    let providerCount: Int
    let avgPrice: String
}

// MARK: - Clusters Teaser

struct ClustersTeaser: View {
    let zipCode: String

    private let clusters = [
        ClusterItem(category: "Internet", icon: "wifi", providerCount: 4, avgPrice: "$71"),
        ClusterItem(category: "Electricity", icon: "bolt.fill", providerCount: 2, avgPrice: "$102"),
        ClusterItem(category: "Phone", icon: "iphone", providerCount: 6, avgPrice: "$65"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Provider Clusters in \(zipCode)").sectionHeader()
                Spacer()
                Button { haptic() } label: {
                    Text("See All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(HomeTheme.accent)
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)

            VStack(spacing: 10) {
                ForEach(clusters) { cluster in
                    ClusterRow(cluster: cluster)
                }
            }
            .padding(.horizontal, HomeTheme.horizontalPadding)
        }
    }
}

// MARK: - Cluster Row

struct ClusterRow: View {
    let cluster: ClusterItem

    var body: some View {
        Button { haptic() } label: {
            HStack(spacing: 14) {
                Image(systemName: cluster.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(HomeTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(HomeTheme.accentLight)
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(cluster.category)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(HomeTheme.primaryText)
                    Text("\(cluster.providerCount) Providers · Avg \(cluster.avgPrice)")
                        .font(.system(size: 13))
                        .foregroundColor(HomeTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(HomeTheme.secondaryText.opacity(0.5))
            }
            .homeCardStyle()
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
