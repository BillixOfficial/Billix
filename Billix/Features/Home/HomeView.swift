import SwiftUI

struct HomeView: View {
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            // Background
            Color.billixLightGreen
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header with Logo and Bell
                    HStack {
                        HStack(spacing: 8) {
                            // Billix Logo
                            Image("billix_logo_new")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 32, height: 32)

                            Text("Billix")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.billixDarkGreen)
                        }

                        Spacer()

                        // Notification Bell
                        Button(action: {
                            hapticFeedback(.light)
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.5))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "bell.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.billixMediumGreen)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    // Compact Profile Card
                    CompactProfileCard()
                        .padding(.horizontal, 20)

                    // Marketplace Highlights
                    MarketplaceHighlightsView()

                    // Compact Bill Activity
                    CompactBillActivityView()

                    // AI Insights
                    AIInsightsCard()
                        .padding(.horizontal, 20)

                    // Consolidated Savings
                    ConsolidatedSavingsCard()
                        .padding(.horizontal, 20)

                    // Quick Actions Grid
                    EnhancedActionButtonsGrid()

                    // Recent Activity Feed
                    RecentActivityFeed()
                        .padding(.horizontal, 20)

                    // Reviews Carousel (Streamlined)
                    StreamlinedReviewsView()
                        .padding(.horizontal, 20)

                    // Bottom Spacer for Nav Bar
                    Spacer()
                        .frame(height: 97)
                }
            }
            .refreshable {
                await refreshData()
            }
        }
    }

    private func refreshData() async {
        isRefreshing = true
        await MainActor.run {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        isRefreshing = false
    }

    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Custom Button Style
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Component Definitions (Temporarily in this file)

struct CompactProfileCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .foregroundColor(.billixLoginTeal.opacity(0.3))
                .background(Color.white)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.gray.opacity(0.1), lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("Ronald Richards")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }

                Text("May 20, 2024")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                HStack(spacing: 12) {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.billixStarGold)
                        Text("4.5")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixDarkGreen)
                    }
                    Text("•").foregroundColor(.gray.opacity(0.5))
                    Text("16 bills")
                        .font(.system(size: 13))
                        .foregroundColor(.billixDarkGreen)
                    Text("•").foregroundColor(.gray.opacity(0.5))
                    Text("$245 saved")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMoneyGreen)
                }
                .font(.system(size: 13))
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct MarketplaceHighlightsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Community Insights")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MarketplaceCard(icon: "chart.line.uptrend.xyaxis", iconColor: .orange, title: "Trending", subtitle: "Electric bills ↑12% this month", backgroundColor: Color.orange.opacity(0.1))
                    MarketplaceCard(icon: "chart.bar.fill", iconColor: .blue, title: "You vs Community", subtitle: "Paying 8% less than avg", backgroundColor: Color.blue.opacity(0.1))
                    MarketplaceCard(icon: "flame.fill", iconColor: .red, title: "Hot Savings", subtitle: "Switch to Mint Mobile", backgroundColor: Color.red.opacity(0.1))
                    MarketplaceCard(icon: "checkmark.seal.fill", iconColor: .green, title: "Trust Score", subtitle: "Top 15% of users", backgroundColor: Color.green.opacity(0.1))
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

struct MarketplaceCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(backgroundColor)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .frame(width: 260)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

struct CompactBillActivityView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill Activity")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            HStack(spacing: 12) {
                BillActivityPill(count: "16", label: "Pending", icon: "clock.fill", backgroundColor: Color.orange.opacity(0.1), textColor: .orange)
                BillActivityPill(count: "8", label: "Done", icon: "checkmark.circle.fill", backgroundColor: Color.green.opacity(0.1), textColor: .green)
                BillActivityPill(count: "5", label: "Active", icon: "bolt.fill", backgroundColor: Color.blue.opacity(0.1), textColor: .blue)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct BillActivityPill: View {
    let count: String
    let label: String
    let icon: String
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(textColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(count)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct AIInsightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)
                Text("Billix found 3 ways to save $127")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                InsightRow(icon: "antenna.radiowaves.left.and.right", text: "Switch to Mint Mobile", savings: "$45/mo")
                InsightRow(icon: "bolt.fill", text: "Better electricity rate available", savings: "$52/mo")
                InsightRow(icon: "wifi", text: "Downgrade internet speed", savings: "$30/mo")
            }

            Button(action: {}) {
                HStack {
                    Text("View All Insights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.billixLoginTeal)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.billixLoginTeal)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(LinearGradient(colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.yellow.opacity(0.2), lineWidth: 1))
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let savings: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.billixLoginTeal)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.billixDarkGreen)
            Spacer()
            Text(savings)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.billixMoneyGreen)
        }
    }
}

struct ConsolidatedSavingsCard: View {
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Total Saved")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                Text("$245")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.billixMoneyGreen)
                Text("This Month")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach([0.3, 0.5, 0.4, 0.7, 0.6, 0.8, 1.0], id: \.self) { height in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(colors: [Color.billixMoneyGreen.opacity(0.7), Color.billixMoneyGreen], startPoint: .top, endPoint: .bottom))
                            .frame(width: 8, height: CGFloat(height) * 50)
                    }
                }
                .frame(height: 50)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Top Category")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.billixMoneyGreen)
                        Text("Utilities")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                        Text("$120")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.billixMoneyGreen)
                    }
                }
            }
        }
        .padding(20)
        .background(LinearGradient(colors: [Color.billixMoneyGreen.opacity(0.08), Color.billixMoneyGreen.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.billixMoneyGreen.opacity(0.2), lineWidth: 1))
    }
}

struct EnhancedActionButtonsGrid: View {
    let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)
                .padding(.horizontal, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                EnhancedActionButton(icon: "message.fill", label: "Chat", gradient: [Color.billixChatBlue, Color.billixChatBlue.opacity(0.8)], badge: "8")
                EnhancedActionButton(icon: "dollarsign.circle.fill", label: "Funding", gradient: [Color.billixFundingPurple, Color.billixFundingPurple.opacity(0.8)], badge: nil)
                EnhancedActionButton(icon: "hand.thumbsup.fill", label: "Vote", gradient: [Color.billixVotePink, Color.billixVotePink.opacity(0.8)], badge: "8")
                EnhancedActionButton(icon: "questionmark.circle.fill", label: "FAQ", gradient: [Color.billixFaqGreen, Color.billixFaqGreen.opacity(0.8)], badge: nil)
                EnhancedActionButton(icon: "arrow.up.doc.fill", label: "Upload", gradient: [Color.billixLoginTeal, Color.billixLoginTeal.opacity(0.8)], badge: nil)
                EnhancedActionButton(icon: "arrow.left.arrow.right", label: "Compare", gradient: [Color.orange, Color.orange.opacity(0.8)], badge: nil)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct EnhancedActionButton: View {
    let icon: String
    let label: String
    let gradient: [Color]
    let badge: String?

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            VStack(spacing: 10) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 70)
                        .background(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(16)

                    if let badge = badge {
                        Text(badge)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: -6, y: 6)
                    }
                }

                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct RecentActivityFeed: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's Happening on Billix")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.billixDarkGreen)

            VStack(spacing: 10) {
                ActivityItem(initials: "SJ", backgroundColor: .purple, text: "Sarah J. saved $32 switching to Mint Mobile", time: "2h ago")
                ActivityItem(initials: "MB", backgroundColor: .blue, text: "New bill comparison: T-Mobile vs Verizon", time: "5h ago")
                ActivityItem(initials: "KL", backgroundColor: .green, text: "Trending: Auto insurance rates ↑8%", time: "1d ago")
                ActivityItem(initials: "DJ", backgroundColor: .orange, text: "David J. verified Comcast overcharge", time: "2d ago")
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct ActivityItem: View {
    let initials: String
    let backgroundColor: Color
    let text: String
    let time: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(backgroundColor.opacity(0.2))
                    .frame(width: 36, height: 36)
                Text(initials)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(backgroundColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)
                Text(time)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
    }
}

struct StreamlinedReviewsView: View {
    @State private var reviewIndex = 0
    let reviews = [
        Review(text: "Great design and super easy to use—managing finances has never been simpler!", author: "Sarah M.", rating: 5),
        Review(text: "Billix helped me save hundreds on my bills. Highly recommend!", author: "Mike T.", rating: 5),
        Review(text: "The bill tracking feature is a game changer for my budget.", author: "Jessica R.", rating: 4)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Community Reviews")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
                Spacer()
                HStack(spacing: 12) {
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
                            .font(.system(size: 14))
                            .foregroundColor(reviewIndex > 0 ? .billixLoginTeal : .gray.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(reviewIndex == 0)

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
                            .font(.system(size: 14))
                            .foregroundColor(reviewIndex < reviews.count - 1 ? .billixLoginTeal : .gray.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .disabled(reviewIndex == reviews.count - 1)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < reviews[reviewIndex].rating ? "star.fill" : "star")
                            .font(.system(size: 14))
                            .foregroundColor(.billixStarGold)
                    }
                }

                Text(reviews[reviewIndex].text)
                    .font(.system(size: 15))
                    .foregroundColor(.billixDarkGreen)
                    .lineSpacing(4)
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                    .id(reviewIndex)

                Text("— \(reviews[reviewIndex].author)")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
            }
        }
        .padding(16)
        .background(LinearGradient(colors: [Color.billixLoginTeal.opacity(0.08), Color.billixLoginTeal.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.billixLoginTeal.opacity(0.2), lineWidth: 1))
    }
}

struct Review {
    let text: String
    let author: String
    let rating: Int
}

#Preview {
    HomeView()
}
