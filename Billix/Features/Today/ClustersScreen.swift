import SwiftUI

/// Browse and join provider clusters in user's area
/// TODO: Implement full cluster browsing, filtering, and join functionality
struct ClustersScreen: View {
    let category: String
    @State private var selectedCategory: String
    @Environment(\.dismiss) private var dismiss

    init(category: String = "All") {
        self.category = category
        _selectedCategory = State(initialValue: category)
    }

    let categories = ["All", "Internet", "Electric", "Mobile", "Gas", "Water"]

    var filteredClusters: [ProviderCluster] {
        if selectedCategory == "All" {
            return ProviderCluster.mockClusters
        }
        return ProviderCluster.mockClusters.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                selectedCategory = cat
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            }) {
                                Text(cat)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(selectedCategory == cat ? .white : .billixDarkGreen)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(selectedCategory == cat ? Color.billixLoginTeal : Color.white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(selectedCategory == cat ? 0 : 0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 8)

                // Clusters list
                VStack(spacing: 16) {
                    ForEach(filteredClusters) { cluster in
                        ClusterCard(cluster: cluster)
                    }
                }
                .padding(.horizontal, 20)

                if filteredClusters.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.stack")
                            .font(.system(size: 48))
                            .foregroundColor(.billixMediumGreen)

                        Text("No clusters found")
                            .font(.system(size: 16))
                            .foregroundColor(.billixDarkGreen)

                        Text("Try selecting a different category")
                            .font(.system(size: 14))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }

                Spacer()
                    .frame(height: 32)
            }
            .padding(.top, 8)
        }
        .background(Color.billixLightGreen.opacity(0.3))
        .navigationTitle("Provider Clusters")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ClusterCard: View {
    let cluster: ProviderCluster
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text(cluster.categoryIcon)
                    .font(.system(size: 24))

                VStack(alignment: .leading, spacing: 4) {
                    Text(cluster.category)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Text("Area: \(cluster.zipPrefix)xx")
                        .font(.system(size: 13))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(cluster.averagePrice)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)

                    Text("avg/mo")
                        .font(.system(size: 11))
                        .foregroundColor(.billixMediumGreen)
                }
            }

            Divider()

            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixLoginTeal)

                    Text("\(cluster.memberCount) members")
                        .font(.system(size: 13))
                        .foregroundColor(.billixDarkGreen)
                }

                HStack(spacing: 6) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixLoginTeal)

                    Text("\(cluster.totalProviders) providers")
                        .font(.system(size: 13))
                        .foregroundColor(.billixDarkGreen)
                }
            }

            // Providers
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Providers:")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)
                        .padding(.top, 4)

                    ForEach(cluster.topProviders) { provider in
                        HStack {
                            Text(provider.name)
                                .font(.system(size: 14))
                                .foregroundColor(.billixDarkGreen)

                            Spacer()

                            if let price = provider.avgPrice {
                                Text("$\(Int(price))/mo")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.billixMoneyGreen)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    HStack {
                        Text(isExpanded ? "Show Less" : "Show Providers")
                            .font(.system(size: 14, weight: .medium))

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.billixLoginTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.billixLoginTeal.opacity(0.1))
                    .cornerRadius(10)
                }

                Button(action: {
                    // TODO: Implement join cluster
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))

                        Text("Join")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.billixLoginTeal)
                    .cornerRadius(10)
                }
            }
        }
        .padding(18)
        .billixCard()
    }
}

#Preview {
    NavigationView {
        ClustersScreen(category: "Internet")
    }
}
