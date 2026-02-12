import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var exploreResetId = UUID()
    @EnvironmentObject var notificationService: NotificationService

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content - All tabs stay in memory to preserve navigation state
            ZStack {
                HomeView()
                    .opacity(selectedTab == 0 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 0)

                ExploreLandingView()
                    .opacity(selectedTab == 1 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 1)

                UploadHubView()
                    .opacity(selectedTab == 2 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 2)

                RewardsHubView(isTabActive: selectedTab == 3)
                    .opacity(selectedTab == 3 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 3)

                ProfileView()
                    .opacity(selectedTab == 4 ? 1 : 0)
                    .allowsHitTesting(selectedTab == 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Bottom Navigation Bar
            CustomBottomNavBar(selectedTab: $selectedTab)
                .edgesIgnoringSafeArea(.bottom)
        }
        .ignoresSafeArea(.keyboard)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToUpload"))) { _ in
            withAnimation {
                selectedTab = 2  // Switch to Upload tab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToGame"))) { _ in
            withAnimation {
                selectedTab = 3  // Switch to Rewards tab (where game is)
            }
        }
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String, color: Color)] = [
        ("house.fill", "Home", Color.billixLoginTeal),
        ("chart.bar.xaxis", "Explore", Color.blue),
        ("arrow.up.doc.fill", "Upload", Color.billixMoneyGreen),
        ("star.circle.fill", "Rewards", Color.billixGoldenAmber),
        ("person.crop.circle.fill", "Profile", Color.billixDarkGreen)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                CustomNavItem(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    color: tabs[index].color,
                    isSelected: selectedTab == index,
                    action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24
            )
            .fill(.white)
            .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
    }
}

// MARK: - Custom Nav Item
struct CustomNavItem: View {
    let icon: String
    let label: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? color : Color.gray.opacity(0.5))
                    .symbolEffect(.bounce, value: isSelected)
                    .frame(height: 24)

                // Label
                Text(label)
                    .font(.system(size: 9, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? color : Color.gray.opacity(0.6))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(NavButtonStyle())
    }
}

// MARK: - Nav Button Style
struct NavButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
}
