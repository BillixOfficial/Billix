import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

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
                    UploadView()
                case 3:
                    HealthView()
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
    }
}

// MARK: - Custom Bottom Navigation Bar
struct CustomBottomNavBar: View {
    @Binding var selectedTab: Int

    let tabs: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("safari.fill", "Explore"),
        ("arrow.left.arrow.right", "Swap"),
        ("car.fill", "Trips"),
        ("person.fill", "Profile")
    ]

    var body: some View {
        HStack(spacing: 31) {
            ForEach(0..<tabs.count, id: \.self) { index in
                CustomNavItem(
                    icon: tabs[index].icon,
                    label: tabs[index].label,
                    isSelected: selectedTab == index,
                    action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.vertical, 12)
        .frame(height: 77)
        .background(
            RoundedRectangle(cornerRadius: 99)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: -5)
        )
    }
}

// MARK: - Custom Nav Item
struct CustomNavItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color(hex: "#4a7c59") : Color(hex: "#a0a2a7"))
                    .symbolEffect(.bounce, value: isSelected)

                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? Color(hex: "#4a7c59") : Color(hex: "#a0a2a7"))
            }
            .frame(width: 40)
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
