import SwiftUI

struct FlashDropsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var flashDrops: [FlashDrop] = FlashDrop.mockDrops
    @State private var selectedCategory: String = "All"

    private let categories = ["All", "Internet", "Electric", "Mobile", "Cable"]

    var filteredDrops: [FlashDrop] {
        if selectedCategory == "All" {
            return flashDrops.filter { !$0.isExpired }
        }
        return flashDrops.filter { $0.category == selectedCategory && !$0.isExpired }
    }

    var body: some View {
        ZStack {
            Color.billixLightGreen.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                FlashDropsHeader(dismiss: dismiss)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Hero Banner
                        FlashDropsHeroBanner()
                            .padding(.horizontal, 18)
                            .padding(.top, 11)

                        // Category Filter
                        CategoryFilterBar(
                            selectedCategory: $selectedCategory,
                            categories: categories
                        )
                        .padding(.horizontal, 18)

                        // Drops List
                        FlashDropsList(drops: filteredDrops)
                            .padding(.horizontal, 18)
                            .padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Header

struct FlashDropsHeader: View {
    let dismiss: DismissAction

    var body: some View {
        HStack(alignment: .center, spacing: 11) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGray)
                    .frame(width: 32, height: 32)
                    .background(Color.white)
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Flash Drops")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.billixDarkGray)

                Text("Limited-time deals")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.billixDarkGray.opacity(0.6))
            }

            Spacer()

            Text("🔥")
                .font(.system(size: 28))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.billixLightGreen)
    }
}

// MARK: - Hero Banner

struct FlashDropsHeroBanner: View {
    @State private var timeRemaining: String = ""

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Text("🔥")
                    .font(.system(size: 32))

                Text("Act Fast!")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.billixDarkGray)
            }

            Text("These exclusive deals expire soon. Claim them before they're gone!")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.billixDarkGray.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 12)

            // Live counter of active deals
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.billixPendingOrange)
                    .frame(width: 8, height: 8)

                Text("3 active deals")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.billixPendingOrange)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.billixPendingOrange.opacity(0.12))
            .cornerRadius(14)
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.billixPendingOrange.opacity(0.15),
                    Color.billixPendingOrange.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.billixPendingOrange.opacity(0.3), lineWidth: 2)
        )
    }
}

// MARK: - Category Filter

struct CategoryFilterBar: View {
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : .billixDarkGray)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(isSelected ? Color.billixPendingOrange : Color.white)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isSelected ? Color.clear : Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// MARK: - Drops List

struct FlashDropsList: View {
    let drops: [FlashDrop]

    var body: some View {
        LazyVStack(spacing: 14) {
            if drops.isEmpty {
                EmptyDropsView()
            } else {
                ForEach(drops) { drop in
                    FlashDropCard(drop: drop)
                }
            }
        }
    }
}

struct FlashDropCard: View {
    let drop: FlashDrop
    @State private var timeRemaining: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Top Section - Provider and Timer
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    // Category Badge
                    HStack(spacing: 4) {
                        Text(drop.categoryIcon)
                            .font(.system(size: 14))
                        Text(drop.category)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.billixPendingOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.billixPendingOrange.opacity(0.12))
                    .cornerRadius(8)

                    // Provider Name
                    Text(drop.provider)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.billixDarkGray)
                }

                Spacer()

                // Timer Badge
                VStack(spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 11))
                        Text(timeRemaining)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Color.red)
                    .cornerRadius(10)

                    Text("left")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.billixDarkGray.opacity(0.6))
                }
            }
            .padding(18)

            // Divider
            Divider()
                .background(Color.gray.opacity(0.15))

            // Bottom Section - Deal Info
            VStack(spacing: 14) {
                // Title
                Text(drop.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGray)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Savings Amount
                HStack(spacing: 8) {
                    Text("💰")
                        .font(.system(size: 20))

                    Text("Save up to")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.billixDarkGray.opacity(0.7))

                    Text("$\(drop.savingsAmount)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.billixMoneyGreen)

                    Spacer()
                }

                // Claim Button
                Button {
                    claimDeal()
                } label: {
                    HStack(spacing: 8) {
                        Text("Claim Deal")
                            .font(.system(size: 16, weight: .semibold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.billixLoginTeal)
                    .cornerRadius(12)
                }
            }
            .padding(18)
            .background(Color.billixLightGreen.opacity(0.3))
        }
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.billixPendingOrange, lineWidth: 2)
        )
        .shadow(color: Color.billixPendingOrange.opacity(0.15), radius: 8, x: 0, y: 4)
        .onAppear {
            updateTimer()
        }
    }

    private func updateTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if drop.isExpired {
                timer.invalidate()
                timeRemaining = "Expired"
            } else {
                timeRemaining = drop.formattedTimeRemaining
            }
        }
    }

    private func claimDeal() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // TODO: Navigate to claim flow or show modal
        print("Claiming deal: \(drop.title)")
    }
}

struct EmptyDropsView: View {
    var body: some View {
        VStack(spacing: 11) {
            Text("🔍")
                .font(.system(size: 48))

            Text("No active deals")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.billixDarkGray)

            Text("Check back soon for new flash drops!")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.billixDarkGray.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .background(Color.white)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    FlashDropsScreen()
}
