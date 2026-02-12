import SwiftUI

/// Main Explore page with tabs for Market Trends and Housing
struct ExploreTabView: View {
    @State private var selectedTab: ExploreTab = .housing
    @StateObject private var locationManager = LocationManager()
    @StateObject private var housingViewModel = HousingSearchViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Custom tab picker - positioned right below nav bar
            TabPickerView(selectedTab: $selectedTab)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

            // Tab content
            TabView(selection: $selectedTab) {
                HousingExploreView(
                    locationManager: locationManager,
                    viewModel: housingViewModel
                )
                .tag(ExploreTab.housing)

                MarketTrendsView(
                    locationManager: locationManager,
                    housingViewModel: housingViewModel,
                    onSwitchToHousing: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = .housing
                        }
                    }
                )
                .tag(ExploreTab.marketTrends)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(Color(hex: "#F3F4F6"))
    }
}

// MARK: - Tab Picker

struct TabPickerView: View {
    @Binding var selectedTab: ExploreTab

    var body: some View {
        // Native iOS Segmented Control Style
        HStack(spacing: 0) {
            ForEach(ExploreTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 15, weight: .medium))

                        Text(tab.title)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .billixDarkTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.billixDarkTeal : Color.clear)
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.12))
        )
    }
}

// MARK: - Tab Enum

enum ExploreTab: String, CaseIterable {
    case housing = "Housing"
    case marketTrends = "Market Trends"

    var title: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .housing:
            return "house.fill"
        case .marketTrends:
            return "chart.bar.fill"
        }
    }
}

struct ExploreTabView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreTabView()
    }
}
