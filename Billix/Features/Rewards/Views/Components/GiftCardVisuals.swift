//
//  GiftCardVisuals.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Simple, clean gift card visual design
//

import SwiftUI

// MARK: - Simple Gift Card Visual

struct SimpleGiftCardVisual: View {
    let value: String?
    let brandName: String
    let color: Color
    let type: RewardType

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [color, color.opacity(0.75)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 80, height: 80)
                    .offset(x: geo.size.width * 0.65, y: -20)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 60, height: 60)
                    .offset(x: -20, y: geo.size.height * 0.6)
            }

            VStack {
                HStack {
                    // Icon based on type
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                HStack {
                    Text(brandName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }

    private var iconName: String {
        switch type {
        case .billCredit:
            return "creditcard.fill"
        case .giftCard:
            return "gift.fill"
        case .digitalGood:
            return "sparkles"
        case .giveawayEntry:
            return "ticket.fill"
        case .customization:
            return "paintpalette.fill"
        }
    }
}

// MARK: - Preview

struct GiftCardVisuals_Simple_Cards_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.horizontal) {
        HStack(spacing: 16) {
        SimpleGiftCardVisual(
        value: "$25",
        brandName: "Gift Card",
        color: .blue,
        type: .giftCard
        )
        .frame(width: 180, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        SimpleGiftCardVisual(
        value: "$15",
        brandName: "Bill Credit",
        color: .green,
        type: .billCredit
        )
        .frame(width: 180, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        
        SimpleGiftCardVisual(
        value: "$50",
        brandName: "Digital",
        color: .purple,
        type: .digitalGood
        )
        .frame(width: 180, height: 110)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
        }
        .background(Color.gray.opacity(0.2))
    }
}
