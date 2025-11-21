import SwiftUI

struct SavingsMeterView: View {
    let monthlyTarget: Double
    let currentSavings: Double

    var progress: Double {
        guard monthlyTarget > 0 else { return 0 }
        return min(currentSavings / monthlyTarget, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Savings Meter")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.billixDarkGray)

                    Text("Track your progress")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.subheadline)
                            .foregroundColor(.billixGoldenAmber)

                        CountUp(end: currentSavings, duration: 1.5, decimals: 0)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.billixGold)
                    }

                    Text("of $\(String(format: "%.0f", monthlyTarget)) goal")
                        .font(.caption)
                        .foregroundColor(.billixDarkTeal)
                }
            }

            VStack(spacing: 8) {
                ProgressBar(
                    progress: progress,
                    height: 12,
                    backgroundColor: Color.gray.opacity(0.2),
                    foregroundColor: progressColor,
                    cornerRadius: 6,
                    animated: true
                )

                HStack {
                    Text("\(Int(progress * 100))% complete")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.billixDarkTeal)

                    Spacer()

                    if currentSavings >= monthlyTarget {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.billixMoneyGreen)
                                .imageScale(.small)
                                .symbolEffect(.bounce, value: currentSavings)

                            Text("Goal reached!")
                                .font(.caption)
                                .foregroundColor(.billixMoneyGreen)
                                .fontWeight(.semibold)
                        }
                    } else {
                        Text("$\(String(format: "%.0f", monthlyTarget - currentSavings)) to go")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.billixCopper)
                    }
                }
            }

            if currentSavings >= monthlyTarget {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.billixGoldenAmber)
                        .imageScale(.medium)
                        .symbolEffect(.bounce, value: currentSavings)

                    Text("Amazing work! You've hit your monthly savings goal.")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.billixDarkGray)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.billixGoldenAmber.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.billixGoldenAmber.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .padding(20)
        .glassMorphic(cornerRadius: 20)
    }

    private var progressColor: Color {
        if progress < 0.33 {
            return .billixCopper
        } else if progress < 0.66 {
            return .billixGoldenAmber
        } else {
            return .billixMoneyGreen
        }
    }
}
