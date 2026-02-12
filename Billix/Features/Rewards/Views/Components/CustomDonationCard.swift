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

                HStack(spacing: 12) {
                    // LEFT: Large Heart Icon (Fixed width)
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "heart.fill")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .frame(width: 60, height: 60)

                    // CENTER: Title & Subtitle (Flexible - can shrink)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Donate to Any Charity")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("You pick the cause, we donate")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                    // RIGHT: Arrow Circle Button (Fixed width)
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color(hex: "#0D9488"))
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.9))

                            Text("10k pts")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .frame(width: 50)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: 160)
            .cornerRadius(20)
            .shadow(color: Color(hex: "#0D9488").opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct CustomDonationCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.billixLightGreen.ignoresSafeArea()
        
        CustomDonationCard(
        onStartRequest: {
        }
        )
        .padding(20)
        }
    }
}
