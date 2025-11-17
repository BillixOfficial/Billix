import SwiftUI

struct InsightsCarouselView: View {
    let insights: [BillAnalysis.Insight]

    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.billixGoldenAmber)
                Text("AI Insights")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.billixNavyBlue)

                Spacer()

                // Page indicator
                if insights.count > 1 {
                    Text("\(currentIndex + 1) of \(insights.count)")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.billixDarkTeal.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 20)

            // Carousel
            if insights.isEmpty {
                emptyState
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(insights.enumerated()), id: \.element.title) { index, insight in
                        InsightCard(insight: insight)
                            .padding(.horizontal, 20)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 180)

                // Dot indicators
                if insights.count > 1 {
                    HStack(spacing: 8) {
                        ForEach(0..<insights.count, id: \.self) { index in
                            Circle()
                                .fill(currentIndex == index ? Color.billixMoneyGreen : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "lightbulb.slash")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No insights available")
                .font(.subheadline)
                .foregroundColor(.billixDarkTeal)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Insight Card

struct InsightCard: View {
    let insight: BillAnalysis.Insight

    @State private var isVisible = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(backgroundColor.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(iconColor)
            }

            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.billixNavyBlue)
                    .lineLimit(2)

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundColor(.billixDarkTeal)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                backgroundColor.opacity(0.15),
                                backgroundColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(backgroundColor.opacity(0.3), lineWidth: 1.5)
            }
        )
        .shadow(color: iconColor.opacity(0.1), radius: 8, x: 0, y: 4)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.9)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }

    // MARK: - Computed Properties

    private var iconName: String {
        switch insight.type {
        case .savings:
            return "dollarsign.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch insight.type {
        case .savings:
            return .billixMoneyGreen
        case .warning:
            return .orange
        case .info:
            return .billixDarkTeal
        case .success:
            return .green
        }
    }

    private var backgroundColor: Color {
        switch insight.type {
        case .savings:
            return .billixMoneyGreen
        case .warning:
            return .orange
        case .info:
            return .billixDarkTeal
        case .success:
            return .green
        }
    }
}
