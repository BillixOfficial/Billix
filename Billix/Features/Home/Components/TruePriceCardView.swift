import SwiftUI

struct TruePriceCardView: View {
    let currentIndex: Double
    let change: Double
    let lastUpdated: String

    @State private var showExplainer = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("TruePrice™ Index")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.billixDarkGray)

                        Button(action: {
                            showExplainer = true
                        }) {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.billixPurple)
                                .imageScale(.small)
                                .symbolEffect(.pulse, value: showExplainer)
                        }
                    }

                    Text("Market benchmark")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        CountUp(end: currentIndex, duration: 1.5, decimals: 2)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.billixDarkGray)

                        Image(systemName: changeIcon)
                            .foregroundColor(changeColor)
                            .imageScale(.small)
                            .symbolEffect(.bounce, value: change)
                    }

                    Text("\(change >= 0 ? "+" : "")\(String(format: "%.2f", change))%")
                        .font(.caption)
                        .foregroundColor(changeColor)
                        .fontWeight(.semibold)
                }
            }

            HStack(spacing: 12) {
                Sparkline(
                    data: generateMockSparklineData(),
                    lineColor: change >= 0 ? .billixCopper : .billixGoldenAmber,
                    lineWidth: 3,
                    showArea: true,
                    areaOpacity: 0.3
                )
                .frame(height: 50)
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.billixDarkTeal)

                    Text("Updated \(lastUpdated)")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }

                Spacer()

                Text("30-day average")
                    .font(.caption)
                    .foregroundColor(.billixDarkTeal)
                    .fontWeight(.medium)
            }
        }
        .padding(20)
        .glassMorphic(cornerRadius: 20)
        .sheet(isPresented: $showExplainer) {
            TruePriceExplainerView()
        }
    }

    private var changeIcon: String {
        change >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private var changeColor: Color {
        change >= 0 ? .billixCopper : .billixGoldenAmber
    }

    private func generateMockSparklineData() -> [Double] {
        // Generate 30 days of mock data trending based on change
        var data: [Double] = []
        let baseValue = currentIndex - (change / 100 * currentIndex)

        for i in 0..<30 {
            let progress = Double(i) / 29.0
            let trendValue = baseValue + (progress * (change / 100 * currentIndex))
            let noise = Double.random(in: -0.5...0.5)
            data.append(trendValue + noise)
        }

        return data
    }
}

struct TruePriceExplainerView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)

                            Spacer()
                        }

                        Text("What is TruePrice™ Index?")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("The TruePrice™ Index is our proprietary benchmark that tracks the average fair market value of essential bills across the United States.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        Text("How it works")
                            .font(.headline)

                        ExplainerPoint(
                            icon: "server.rack",
                            title: "Data Collection",
                            description: "We analyze millions of bills from verified users across all 50 states"
                        )

                        ExplainerPoint(
                            icon: "chart.bar.xaxis",
                            title: "Normalization",
                            description: "Regional variations and service tiers are normalized to create a baseline"
                        )

                        ExplainerPoint(
                            icon: "brain.head.profile",
                            title: "AI Analysis",
                            description: "Machine learning identifies patterns and predicts fair pricing"
                        )

                        ExplainerPoint(
                            icon: "dollarsign.circle",
                            title: "Your Savings",
                            description: "Compare your bills against the index to find overpayments"
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why it matters")
                            .font(.headline)

                        Text("Most people overpay for essential services without realizing it. The TruePrice™ Index gives you a data-driven benchmark to ensure you're never paying more than you should.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.green.opacity(0.1))
                    )

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Got it!")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("TruePrice™ Index")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct ExplainerPoint: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .imageScale(.large)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
