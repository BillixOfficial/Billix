//
//  HomePageZones.swift
//  Billix
//
//  Home page zone components for the redesigned dashboard
//

import SwiftUI

// MARK: - Utility Checkup Zone

struct UtilityCheckupZone: View {
    @State private var selectedCategory: String? = nil

    private let categories = [
        ("Electric", "bolt.fill", Color(hex: "#F59E0B")),
        ("Gas", "flame.fill", Color(hex: "#EF4444")),
        ("Water", "drop.fill", Color(hex: "#3B82F6")),
        ("Internet", "wifi", Color(hex: "#8B5CF6"))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("30-Second Checkup")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                Text("Regional signals")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }

            HStack(spacing: 10) {
                ForEach(categories, id: \.0) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = selectedCategory == category.0 ? nil : category.0
                        }
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == category.0 ? category.2 : category.2.opacity(0.1))
                                    .frame(width: 44, height: 44)

                                Image(systemName: category.1)
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedCategory == category.0 ? .white : category.2)
                            }

                            Text(category.0)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#2D3B35"))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            if let selected = selectedCategory {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4CAF7A"))

                    Text("Your \(selected.lowercased()) rates are competitive for your area")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#2D3B35"))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "#4CAF7A").opacity(0.1))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Utility Insight Zone

struct UtilityInsightZone: View {
    let zipCode: String
    let onUploadTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Rate Alert Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "#F59E0B"))

                        Text("Rate Alert")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))
                    }

                    Text("Electric rates up 3.2% in your area this month")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                        .lineLimit(2)

                    Spacer()

                    Text("View details →")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 110)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "#F59E0B").opacity(0.08))
                )

                // Upload CTA Card
                Button(action: onUploadTap) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "#5B8A6B").opacity(0.1))
                                .frame(width: 40, height: 40)

                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 18))
                                .foregroundColor(Color(hex: "#5B8A6B"))
                        }

                        Text("Upload Bill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(Color(hex: "#2D3B35"))

                        Text("Get personalized insights")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "#8B9A94"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .frame(height: 110)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(hex: "#5B8A6B").opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Learn to Lower Zone

struct LearnToLowerZone: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#F59E0B"))

                Text("Quick Tip")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }

            Text("Switching to budget billing can help smooth out seasonal spikes in your electric bill.")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "#8B9A94"))
                .lineLimit(3)

            Button {
                // Learn more
            } label: {
                Text("Learn how →")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#F59E0B").opacity(0.06))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Community Poll Zone

struct CommunityPollZoneNew: View {
    @State private var selectedOption: Int? = nil
    @State private var hasVoted = false

    private let question = "How do you handle unexpected bill increases?"
    private let options = [
        "Call provider immediately",
        "Wait and see next month",
        "Switch providers",
        "Reduce usage"
    ]
    private let votes = [42, 18, 25, 15] // percentages

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5BA4D4"))

                Text("Community Poll")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Spacer()

                if hasVoted {
                    Text("248 votes")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }
            }

            Text(question)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#2D3B35"))

            VStack(spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        if !hasVoted {
                            withAnimation(.spring(response: 0.3)) {
                                selectedOption = index
                                hasVoted = true
                            }
                        }
                    } label: {
                        HStack {
                            Text(option)
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            Spacer()

                            if hasVoted {
                                Text("\(votes[index])%")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(selectedOption == index ? Color(hex: "#5B8A6B") : Color(hex: "#8B9A94"))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedOption == index ? Color(hex: "#5B8A6B").opacity(0.1) : Color(hex: "#F7F9F8"))

                                if hasVoted {
                                    GeometryReader { geo in
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "#5B8A6B").opacity(0.15))
                                            .frame(width: geo.size.width * CGFloat(votes[index]) / 100)
                                    }
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedOption == index ? Color(hex: "#5B8A6B") : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(hasVoted)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Invite & Earn Banner

struct InviteEarnBannerNew: View {
    var body: some View {
        Button {
            // Open referral flow
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#9B7EB8").opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "gift.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#9B7EB8"))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite friends, earn rewards")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "#2D3B35"))

                    Text("Get $5 for each friend who uploads a bill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#8B9A94"))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#9B7EB8").opacity(0.08), Color(hex: "#9B7EB8").opacity(0.03)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "#9B7EB8").opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}
