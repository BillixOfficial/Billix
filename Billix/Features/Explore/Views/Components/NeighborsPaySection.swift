//
//  NeighborsPaySection.swift
//  Billix
//
//  Created by Claude Code on 1/7/26.
//  See What Your Neighbors Pay section with 2 large cards
//

import SwiftUI

struct NeighborsPaySection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header - left aligned
            Text("See What Your Neighbors Pay")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(hex: "#2D3B35"))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            // Placeholder card - Housing Trends (navigates to ExploreTabView)
            NavigationLink(destination: ExploreTabView()) {
                VStack(spacing: 0) {
                    // Placeholder image area
                    ZStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 140)

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(Color.gray.opacity(0.4))
                    }

                    // Content section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Housing Trends")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Text("Explore rental markets")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "#8B9A94"))
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                    }
                    .padding(16)
                }
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
        }
    }
}

#Preview("Neighbors Pay Section") {
    NavigationStack {
        NeighborsPaySection()
            .background(Color.billixCreamBeige.opacity(0.3))
    }
}
