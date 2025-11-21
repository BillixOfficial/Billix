import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var billActivityExpanded = false
    @State private var reviewIndex = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [
                    Color.billixLightGreen,
                    Color.billixLightGreen.opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header with Logo and Bell Icon
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "asterisk.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.billixMediumGreen)
                                .rotationEffect(.degrees(scrollOffset * 0.1))
                                .animation(.spring(response: 0.3), value: scrollOffset)

                            Text("Billix")
                                .font(.system(size: 23, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)
                        }

                        Spacer()

                        Button(action: {
                            hapticFeedback(.light)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "bell.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.billixMediumGreen)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .offset(y: max(-scrollOffset * 0.3, -20))

                    // Profile Section with Parallax
                    VStack(spacing: 16) {
                        // Profile Image with breathing animation
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 136.5, height: 136.5)
                            .foregroundColor(.gray)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white, Color.billixLightGreen.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white, Color.billixMediumGreen.opacity(0.3)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .scaleEffect(1.0 - min(scrollOffset / 1000, 0.15))

                        // User Info
                        VStack(spacing: 8) {
                            Text("Ronald Richards")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)

                            Text("May 20, 2024")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixLightGreenText)
                        }
                        .opacity(1.0 - min(scrollOffset / 300, 0.6))

                        // Rating with animation
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.billixStarGold)
                                .symbolEffect(.bounce, value: reviewIndex)

                            Text("4.5")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.billixStarGold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.billixBorderGreen, lineWidth: 1)
                                )
                                .shadow(color: Color.billixStarGold.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                    }
                    .padding(.top, 20)
                    .offset(y: -scrollOffset * 0.15)

                    // Bill Activity Header
                    Button(action: {
                        hapticFeedback(.medium)
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            billActivityExpanded.toggle()
                        }
                    }) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: billActivityExpanded ? "chart.bar.fill" : "chart.bar")
                                    .font(.system(size: 16))
                                    .foregroundColor(.billixMediumGreen)
                                    .symbolEffect(.bounce, value: billActivityExpanded)

                                Text("Bill Activity")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.billixMediumGreen)
                            }

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.billixMediumGreen)
                                .rotationEffect(.degrees(billActivityExpanded ? 180 : 0))
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 21)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(billActivityExpanded ? 0.1 : 0.05), radius: billActivityExpanded ? 10 : 6, x: 0, y: 0)
                        )
                        .padding(.horizontal, 5)
                    }
                    .buttonStyle(InteractiveCardStyle())

                    // Bill Activity Expanded Content
                    if billActivityExpanded {
                        VStack(spacing: 4) {
                            // Pending Section
                            PendingBillsCard()
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                                    removal: .scale(scale: 0.95).combined(with: .opacity)
                                ))

                            // Completed Section
                            BillStatusCard(
                                icon: "checkmark.circle",
                                title: "Completed",
                                count: 8,
                                color: .billixCompletedGreenText,
                                backgroundColor: .billixCompletedGreen
                            )
                            .transition(.scale.combined(with: .opacity))

                            // Active Section
                            BillStatusCard(
                                icon: "clock.fill",
                                title: "Active",
                                count: 5,
                                color: .billixActiveBlueText,
                                backgroundColor: .billixActiveBlue
                            )
                            .transition(.scale.combined(with: .opacity))
                        }
                        .padding(.horizontal, 5)
                        .padding(.bottom, 8)
                    }

                    // Your Savings With Billix
                    SavingsProgressCard()
                        .padding(.horizontal, 5)
                        .transition(.scale.combined(with: .opacity))

                    // Savings Chart Section
                    SavingsChartView()
                        .padding(.horizontal, 5)
                        .transition(.scale.combined(with: .opacity))

                    // Percentage Chart Section
                    PercentageChartView()
                        .padding(.horizontal, 5)
                        .transition(.scale.combined(with: .opacity))

                    // Learn More Card
                    LearnMoreCardView()
                        .padding(.horizontal, 5)
                        .transition(.scale.combined(with: .opacity))

                    // Review Card and Action Buttons Row
                    HStack(spacing: 4) {
                        // Review Card
                        ReviewCardView(reviewIndex: $reviewIndex)

                        // Action Buttons Grid
                        ActionButtonsGridView()
                    }
                    .padding(.horizontal, 5)
                    .transition(.scale.combined(with: .opacity))

                    // Bottom padding for navigation bar
                    Spacer()
                        .frame(height: 97)
                }
                .background(
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    private func refreshData() async {
        isRefreshing = true
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Custom Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct InteractiveCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Pending Bills Card
struct PendingBillsCard: View {
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundColor(.billixPendingOrangeText)
                    .rotationEffect(.degrees(isVisible ? 360 : 0))

                Text("Pending")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixPendingOrangeText)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            // Count Badge
            HStack {
                Spacer()

                Text("16")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixPendingOrangeText)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white)
                            .shadow(color: Color.billixPendingOrangeText.opacity(0.2), radius: 8, x: 0, y: 2)
                    )
                    .scaleEffect(isVisible ? 1.0 : 0.5)
            }
            .padding(.horizontal, 14)
            .padding(.top, -52)

            // Bill Icons
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        )
                        .padding(.trailing, -10)
                        .scaleEffect(isVisible ? 1.0 : 0.8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.05), value: isVisible)
                }

                Text("More")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.leading, 20)
                    .opacity(isVisible ? 1 : 0)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 168)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.billixPendingOrange, Color.billixPendingOrange.opacity(0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.billixPendingOrangeText.opacity(0.15), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Bill Status Card
struct BillStatusCard: View {
    let icon: String
    let title: String
    let count: Int
    let color: Color
    let backgroundColor: Color

    @State private var isVisible = false

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .symbolEffect(.bounce, value: isVisible)

                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()

            Text("\(count)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 2)
                )
                .scaleEffect(isVisible ? 1.0 : 0.5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(backgroundColor)
                .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.1)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Savings Progress Card
struct SavingsProgressCard: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Savings with Billix")
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            // Progress Bar
            VStack(alignment: .leading, spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 99)
                            .fill(Color(hex: "#faf4f0"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 99)
                                    .stroke(Color(hex: "#f7e4cf"), lineWidth: 1)
                            )
                            .frame(height: 18)

                        // Animated Progress
                        RoundedRectangle(cornerRadius: 99)
                            .fill(
                                LinearGradient(
                                    colors: [Color.billixSavingsYellow, Color.billixSavingsOrange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: progress * 100, height: 12)
                            .padding(.leading, 3)
                            .shadow(color: Color(hex: "#f09a3d").opacity(0.5), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(height: 18)

                HStack(spacing: 4) {
                    Text("You've ")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixSavingsYellow)

                    Text("saved ")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixSavingsYellow)

                    Text("$245")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.billixSavingsOrange)

                    Text(" in fees!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixSavingsYellow)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Savings Chart View
struct SavingsChartView: View {
    @State private var chartAnimation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Savings with Billix")
                .font(.system(size: 21, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            // Chart Area
            VStack(spacing: 16) {
                // Y-axis labels and chart
                HStack(alignment: .bottom, spacing: 0) {
                    // Y-axis
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach([300, 250, 200, 150, 50, 0], id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.black.opacity(0.5))
                                .frame(height: value == 0 ? 20 : 42)
                        }
                    }
                    .padding(.trailing, 8)

                    // Chart bars
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { index in
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, index == 5 ? 0 : 41)
                            }
                        }

                        // Bars with animation
                        HStack(alignment: .bottom, spacing: 16) {
                            Spacer()

                            // Cashback Earnings
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.billixChartBlue, Color.billixChartBlue.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 88, height: chartAnimation ? 168 : 0)
                                    .shadow(color: Color.billixChartBlue.opacity(0.3), radius: 8, x: 0, y: 4)

                                Text("Cashback Earnings")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.billixChartBlue)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 88)
                            }

                            Spacer()

                            // Late Fees
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.billixChartGreen, Color.billixChartGreen.opacity(0.8)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 88, height: chartAnimation ? 37 : 0)
                                    .shadow(color: Color.billixChartGreen.opacity(0.3), radius: 8, x: 0, y: 4)

                                Text("Late Fees")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.billixChartGreen)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 88)
                            }

                            Spacer()
                        }
                    }
                    .frame(height: 252)
                }
            }
            .padding(.horizontal, 16)

            Text("This is 45% of the late fees you could have paid.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.billixMediumGreen)
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                chartAnimation = true
            }
        }
    }
}

// MARK: - Percentage Chart View
struct PercentageChartView: View {
    @State private var barsVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("With Billix, you've saved $245 in late fees—45% of the usual cost!")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 16)
                .padding(.top, 20)

            // Percentage Chart
            HStack(alignment: .bottom, spacing: 0) {
                // Y-axis
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach([100, 75, 50, 25, 0], id: \.self) { value in
                        Text("\(value)%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.black.opacity(0.5))
                            .frame(height: value == 0 ? 20 : 42)
                    }
                }
                .padding(.trailing, 8)

                // Bars
                VStack {
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        VStack(spacing: 0) {
                            ForEach(0..<5, id: \.self) { index in
                                Rectangle()
                                    .fill(index == 1 ? Color.gray.opacity(0.25) : Color.gray.opacity(0.15))
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                                    .padding(.bottom, index == 4 ? 0 : 41)
                            }
                        }

                        // Category bars
                        HStack(alignment: .bottom, spacing: 0) {
                            Spacer()

                            CategoryBarView(
                                label: "rent",
                                color: Color(hex: "#a89edc"),
                                height: barsVisible ? 124 : 0
                            )

                            Spacer()

                            CategoryBarView(
                                label: "utility",
                                color: Color(hex: "#72afc6"),
                                height: barsVisible ? 83 : 0
                            )

                            Spacer()

                            CategoryBarView(
                                label: "internet",
                                color: Color(hex: "#f0a59f"),
                                height: barsVisible ? 41 : 0
                            )

                            Spacer()

                            CategoryBarView(
                                label: "Water",
                                color: Color(hex: "#98c9a6"),
                                height: barsVisible ? 124 : 0
                            )

                            Spacer()
                        }
                    }
                    .frame(height: 168)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                barsVisible = true
            }
        }
    }
}

// MARK: - Category Bar View
struct CategoryBarView: View {
    let label: String
    let color: Color
    let height: CGFloat

    var body: some View {
        VStack(spacing: 4) {
            // Dotted line bar with animation
            VStack(spacing: 2) {
                ForEach(0..<Int(height / 6), id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .frame(width: 2, height: 4)
                        .opacity(Double(index) / Double(max(1, Int(height / 6))))
                }
            }
            .frame(height: height, alignment: .bottom)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(color)
        }
    }
}

// MARK: - Learn More Card View
struct LearnMoreCardView: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            HStack(spacing: 16) {
                // Icon and Text
                HStack(spacing: 8) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.billixSavingsOrange)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 21)
                                .fill(Color(hex: "#fff7e3"))
                                .shadow(color: Color.billixSavingsOrange.opacity(0.2), radius: 4, x: 0, y: 2)
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Save ")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                        + Text("more by swapping bills watch your savings grow!")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                    }
                    .frame(width: 150)
                }

                Spacer()

                // Learn More Button
                Text("Learn More")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#4a7c59"), Color(hex: "#3d6549")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color(hex: "#4a7c59").opacity(0.4), radius: 8, x: 0, y: 4)
                    )
            }
            .padding(16)
            .frame(height: 151)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(InteractiveCardStyle())
    }
}

// MARK: - Review Card View
struct ReviewCardView: View {
    @Binding var reviewIndex: Int

    let reviews = [
        "Great design and super easy to use—managing finances has never been simpler!",
        "Billix helped me save hundreds on my bills. Highly recommend!",
        "The bill tracking feature is a game changer for my budget."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Review")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixPurpleAccent)

                Spacer()

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.billixPurpleAccent.opacity(0.3), Color.billixPurpleAccent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            Text(reviews[reviewIndex])
                .font(.system(size: 14))
                .foregroundColor(.billixPurpleLight)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .id(reviewIndex)

            Spacer()

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixPurpleAccent)

                    Text("4.5")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixPurpleAccent)
                }

                Spacer()

                HStack(spacing: 4) {
                    Button(action: {
                        if reviewIndex > 0 {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                reviewIndex -= 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12))
                            .foregroundColor(.billixPurpleAccent)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(action: {
                        if reviewIndex < reviews.count - 1 {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                reviewIndex += 1
                            }
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.billixPurpleAccent)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 188, height: 198)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.billixPurpleAccent.opacity(0.15), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Action Buttons Grid View
struct ActionButtonsGridView: View {
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                ActionButtonView(
                    icon: "message.fill",
                    label: "Chat",
                    color: .billixChatBlue,
                    backgroundColor: Color.billixChatBlueBg.opacity(0.3),
                    badgeCount: 8
                )

                ActionButtonView(
                    icon: "dollarsign.circle.fill",
                    label: "Funding",
                    color: .billixFundingPurple,
                    backgroundColor: Color.billixFundingPurple.opacity(0.1),
                    badgeCount: nil
                )
            }

            HStack(spacing: 4) {
                ActionButtonView(
                    icon: "questionmark.circle.fill",
                    label: "FAQ",
                    color: .billixFaqGreen,
                    backgroundColor: Color.billixFaqGreen.opacity(0.1),
                    badgeCount: nil
                )

                ActionButtonView(
                    icon: "chart.bar.fill",
                    label: "Vote",
                    color: .billixVotePink,
                    backgroundColor: Color.billixVotePink.opacity(0.1),
                    badgeCount: 8
                )
            }
        }
        .frame(width: 188)
    }
}

// MARK: - Action Button View
struct ActionButtonView: View {
    let icon: String
    let label: String
    let color: Color
    let backgroundColor: Color
    let badgeCount: Int?

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                        .frame(width: 38, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 21)
                                .fill(backgroundColor)
                                .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
                        )

                    Text(label)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(color)
                }
                .frame(width: 92, height: 97)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
                )

                if let count = badgeCount {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(label == "Chat" ? Color(hex: "#944ab6") : Color(hex: "#5dc176"))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(label == "Chat" ? Color(hex: "#fae7fc") : Color(hex: "#edfbf0"))
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        )
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    HomeView()
}
