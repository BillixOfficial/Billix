//
//  FeaturedFeedView.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Main feed container with filter bar and property cards
//

import SwiftUI

struct FeaturedFeedView: View {
    @ObservedObject var viewModel: HousingSearchViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Sticky filter bar
            FeedFiltersBar(viewModel: viewModel)

            // Feed header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Featured Homes")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("\(viewModel.featuredListings.count) listings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await viewModel.loadFeaturedFeed()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.billixDarkTeal)
                }
                .accessibilityLabel("Refresh feed")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            // Property cards
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.featuredListings) { property in
                        PropertyFeedCard(
                            property: property,
                            fairValue: viewModel.fairValueIndicator(for: property.rent ?? 2000)
                        )
                    }

                    // Bottom spacing for floating button
                    Color.clear.frame(height: 80)
                }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct FeaturedFeedView_Featured_Feed_View_Previews: PreviewProvider {
    static var previews: some View {
        FeaturedFeedView(viewModel: HousingSearchViewModel())
        .background(
        LinearGradient(
        colors: [Color(hex: "F8F9FA"), Color(hex: "E9ECEF")],
        startPoint: .top,
        endPoint: .bottom
        )
        )
    }
}
