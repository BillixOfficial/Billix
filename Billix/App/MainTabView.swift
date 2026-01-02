import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showPollView = false
    @State private var showQuizView = false
    @State private var showTipView = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                case 1:
                    ExploreView()
                case 2:
                    UploadHubView()
                case 3:
                    RewardsHubView()
                case 4:
                    ProfileView()
                default:
                    HomeView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom Bottom Navigation Bar
            CustomBottomNavBar(selectedTab: $selectedTab)
                .padding(.horizontal, 5)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showPollView) {
            PollView()
        }
        .sheet(isPresented: $showQuizView) {
            QuizView()
        }
        .sheet(isPresented: $showTipView) {
            TipView()
        }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToPoll"))) { _ in
            showPollView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToQuiz"))) { _ in
            showQuizView = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTip"))) { _ in
            showTipView = true
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
        ("star.circle.fill", "Rewards", Color.billixPrizeOrange),
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
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .frame(height: 72)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -2)
        )
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
            VStack(spacing: 6) {
                ZStack {
                    // Active indicator background
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(color.opacity(0.12))
                            .frame(width: 56, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }

                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 20, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? color : Color.gray.opacity(0.5))
                        .symbolEffect(.bounce, value: isSelected)
                }
                .frame(height: 32)

                Text(label)
                    .font(.system(size: isSelected ? 11 : 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? color : Color.gray.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
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

#Preview {
    MainTabView()
}
