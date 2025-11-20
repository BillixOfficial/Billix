import SwiftUI

/// Main Explore page with tabs for Bills and Housing marketplaces
struct ExploreTabView: View {
    @State private var selectedTab: ExploreTab = .bills

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom tab picker
                TabPickerView(selectedTab: $selectedTab)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Tab content
                TabView(selection: $selectedTab) {
                    BillsExploreView()
                        .tag(ExploreTab.bills)

                    HousingExploreView()
                        .tag(ExploreTab.housing)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.billixCreamBeige.opacity(0.3))
        }
    }
}

// MARK: - Tab Picker

struct TabPickerView: View {
    @Binding var selectedTab: ExploreTab
    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ExploreTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Text(tab.icon)
                                .font(.title3)

                            Text(tab.title)
                                .font(.headline)
                                .fontWeight(selectedTab == tab ? .bold : .medium)
                        }
                        .foregroundColor(selectedTab == tab ? .billixNavyBlue : .billixDarkTeal.opacity(0.6))
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)

                        // Underline indicator
                        if selectedTab == tab {
                            Rectangle()
                                .fill(Color.billixMoneyGreen)
                                .frame(height: 3)
                                .matchedGeometryEffect(id: "tab", in: animation)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 3)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
        )
    }
}

// MARK: - Tab Enum

enum ExploreTab: String, CaseIterable {
    case bills = "Bills"
    case housing = "Housing"

    var title: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .bills:
            return "⚡"
        case .housing:
            return "🏠"
        }
    }
}

// MARK: - Placeholder Housing View

struct HousingExploreView: View {
    var body: some View {
        ZStack {
            Color.billixCreamBeige.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.billixMoneyGreen)

                Text("Housing Marketplace")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.billixNavyBlue)

                Text("Coming in Phase 4")
                    .font(.body)
                    .foregroundColor(.billixDarkTeal)
            }
        }
    }
}

#Preview {
    ExploreTabView()
}
