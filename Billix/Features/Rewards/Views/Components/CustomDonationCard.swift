//
//  CustomDonationCard.swift
//  Billix
//
//  "Golden Ticket" entry card for custom charity donations
//  Users can donate to ANY registered non-profit
//

import SwiftUI

struct CustomDonationCard: View {
    let onStartRequest: () -> Void

    var body: some View {
        Button(action: onStartRequest) {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        Color(hex: "#0D9488"), // Teal
                        Color(hex: "#059669")  // Emerald
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Decorative sparkles pattern
                GeometryReader { geometry in
                    ForEach(0..<15) { index in
                        let randomX = CGFloat.random(in: 0...geometry.size.width)
                        let randomY = CGFloat.random(in: 0...geometry.size.height)

                        Image(systemName: "sparkle")
                            .font(.system(size: CGFloat.random(in: 8...14)))
                            .foregroundColor(.white.opacity(Double.random(in: 0.1...0.3)))
                            .position(x: randomX, y: randomY)
                    }
                }

                HStack(spacing: 20) {
                    // LEFT: Large Heart Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }

                    // CENTER: Title & Subtitle
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Donate to Any Charity")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("You pick the cause, we send the funds")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    // RIGHT: Start Request Button
                    VStack(spacing: 6) {
                        Text("Start Request")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#0D9488"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.9))

                            Text("From 10k pts")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .padding(24)
            }
            .frame(height: 160)
            .cornerRadius(20)
            .shadow(color: Color(hex: "#0D9488").opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.billixLightGreen.ignoresSafeArea()

        CustomDonationCard(
            onStartRequest: {
                print("Start donation request")
            }
        )
        .padding(20)
    }
}
