//
//  GiftCardVisuals.swift
//  Billix
//
//  Created by Claude Code on 11/26/25.
//  Brand-specific gift card visual designs
//  These are stylized representations using brand signature colors and patterns
//

import SwiftUI

// MARK: - Amazon Gift Card Visual

struct AmazonGiftCardVisual: View {
    let value: String?

    private let amazonOrange = Color(red: 255/255, green: 153/255, blue: 0/255)
    private let amazonDark = Color(red: 35/255, green: 47/255, blue: 62/255)

    var body: some View {
        ZStack {
            // Dark background
            amazonDark

            // Subtle pattern
            VStack(spacing: 8) {
                ForEach(0..<6) { _ in
                    HStack(spacing: 12) {
                        ForEach(0..<8) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.03))
                                .frame(width: 20, height: 20)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                HStack {
                    // Amazon-style "a" with smile
                    VStack(alignment: .leading, spacing: 2) {
                        Text("amazon")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        // Orange smile/arrow
                        AmazonSmileCurve()
                            .stroke(amazonOrange, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 60, height: 10)
                    }

                    Spacer()

                    // Gift card value
                    if let value = value {
                        Text(value)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

struct AmazonSmileCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 5, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + 5)
        )
        // Arrow head
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 3))
        return path
    }
}

// MARK: - Starbucks Gift Card Visual

struct StarbucksGiftCardVisual: View {
    let value: String?

    private let starbucksGreen = Color(red: 0/255, green: 112/255, blue: 74/255)
    private let starbucksLight = Color(red: 30/255, green: 140/255, blue: 100/255)

    var body: some View {
        ZStack {
            // Green gradient background
            LinearGradient(
                colors: [starbucksGreen, starbucksLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Stars pattern
            GeometryReader { geo in
                ForEach(0..<12, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: CGFloat.random(in: 6...12)))
                        .foregroundColor(.white.opacity(0.08))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }

            VStack {
                // Siren-inspired circular logo
                ZStack {
                    Circle()
                        .fill(starbucksGreen)
                        .frame(width: 50, height: 50)

                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 44, height: 44)

                    // Simplified crown/star in center
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .padding(.top, 12)

                Spacer()

                HStack {
                    Text("Starbucks")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Target Gift Card Visual

struct TargetGiftCardVisual: View {
    let value: String?

    private let targetRed = Color(red: 204/255, green: 0/255, blue: 0/255)

    var body: some View {
        ZStack {
            // White background with red accent
            Color.white

            // Large bullseye in background
            ZStack {
                Circle()
                    .fill(targetRed)
                    .frame(width: 140, height: 140)

                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(targetRed)
                    .frame(width: 60, height: 60)

                Circle()
                    .fill(Color.white)
                    .frame(width: 25, height: 25)
            }
            .offset(x: 40, y: -10)
            .opacity(0.15)

            VStack {
                HStack {
                    // Target logo
                    ZStack {
                        Circle()
                            .fill(targetRed)
                            .frame(width: 36, height: 36)

                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)

                        Circle()
                            .fill(targetRed)
                            .frame(width: 12, height: 12)
                    }

                    Text("Target")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(targetRed)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                HStack {
                    Text("GiftCard")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(targetRed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - DoorDash Gift Card Visual

struct DoorDashGiftCardVisual: View {
    let value: String?

    private let doordashRed = Color(red: 255/255, green: 45/255, blue: 45/255)

    var body: some View {
        ZStack {
            // White background
            Color.white

            // Red accent wave at top
            VStack(spacing: 0) {
                doordashRed
                    .frame(height: 40)

                DoorDashWave()
                    .fill(doordashRed)
                    .frame(height: 20)

                Spacer()
            }

            VStack {
                HStack {
                    // DoorDash "D" icon style
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                            .frame(width: 32, height: 32)

                        Text("D")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(doordashRed)
                    }

                    Text("DoorDash")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                Spacer()

                HStack {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(doordashRed.opacity(0.6))

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(doordashRed)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

struct DoorDashWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height * 0.3),
            control: CGPoint(x: rect.midX, y: rect.height)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Uber Gift Card Visual

struct UberGiftCardVisual: View {
    let value: String?

    var body: some View {
        ZStack {
            // Black background
            Color.black

            // Subtle grid pattern
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 20
                    for x in stride(from: 0, to: geo.size.width, by: spacing) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                    for y in stride(from: 0, to: geo.size.height, by: spacing) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                }
                .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
            }

            VStack {
                HStack {
                    Text("Uber")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()

                HStack {
                    // Car icon
                    Image(systemName: "car.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.4))

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Netflix Gift Card Visual

struct NetflixGiftCardVisual: View {
    let value: String?

    private let netflixRed = Color(red: 229/255, green: 9/255, blue: 20/255)

    var body: some View {
        ZStack {
            // Black/dark gradient background
            LinearGradient(
                colors: [Color(red: 20/255, green: 20/255, blue: 20/255), .black],
                startPoint: .top,
                endPoint: .bottom
            )

            // Red glow effect
            Circle()
                .fill(netflixRed.opacity(0.3))
                .blur(radius: 40)
                .frame(width: 100, height: 100)
                .offset(x: -30, y: 20)

            VStack {
                HStack {
                    // Netflix "N" logo style
                    NetflixNLogo()
                        .frame(width: 24, height: 36)

                    Text("NETFLIX")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(2)
                        .foregroundColor(netflixRed)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                HStack {
                    Text("Gift Card")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

struct NetflixNLogo: View {
    private let netflixRed = Color(red: 229/255, green: 9/255, blue: 20/255)

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Left bar
                Rectangle()
                    .fill(netflixRed)
                    .frame(width: geo.size.width * 0.25)
                    .offset(x: -geo.size.width * 0.35)

                // Right bar
                Rectangle()
                    .fill(netflixRed)
                    .frame(width: geo.size.width * 0.25)
                    .offset(x: geo.size.width * 0.35)

                // Diagonal
                Rectangle()
                    .fill(netflixRed)
                    .frame(width: geo.size.width * 0.25)
                    .rotationEffect(.degrees(20))
            }
        }
    }
}

// MARK: - Spotify Gift Card Visual

struct SpotifyGiftCardVisual: View {
    let value: String?

    private let spotifyGreen = Color(red: 30/255, green: 215/255, blue: 96/255)

    var body: some View {
        ZStack {
            // Dark gradient
            LinearGradient(
                colors: [Color(red: 25/255, green: 25/255, blue: 25/255), Color(red: 18/255, green: 18/255, blue: 18/255)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Sound waves pattern
            HStack(spacing: 3) {
                ForEach(0..<20, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(spotifyGreen.opacity(0.1))
                        .frame(width: 4, height: CGFloat.random(in: 20...60))
                }
            }
            .offset(y: 10)

            VStack {
                HStack {
                    // Spotify icon
                    ZStack {
                        Circle()
                            .fill(spotifyGreen)
                            .frame(width: 32, height: 32)

                        // Sound bars
                        VStack(spacing: 3) {
                            ForEach(0..<3, id: \.self) { i in
                                SpotifyArc(index: i)
                                    .stroke(Color.black, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                    .frame(width: 16 - CGFloat(i * 4), height: 8 - CGFloat(i * 2))
                            }
                        }
                        .rotationEffect(.degrees(-20))
                    }

                    Text("Spotify")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                Spacer()

                HStack {
                    Text("Premium")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(spotifyGreen.opacity(0.7))

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(spotifyGreen)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

struct SpotifyArc: Shape {
    let index: Int

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY),
            radius: rect.width / 2,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        return path
    }
}

// MARK: - Billix Gift Card Visual (Bill Credit)

struct BillixGiftCardVisual: View {
    let value: String?

    var body: some View {
        ZStack {
            // Billix green gradient
            LinearGradient(
                colors: [Color.billixMoneyGreen, Color.billixMoneyGreen.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Coin pattern
            GeometryReader { geo in
                ForEach(0..<8, id: \.self) { i in
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: CGFloat.random(in: 30...60))
                        .position(
                            x: CGFloat.random(in: 0...geo.size.width),
                            y: CGFloat.random(in: 0...geo.size.height)
                        )
                }
            }

            VStack {
                HStack {
                    // Billix coin logo
                    ZStack {
                        Circle()
                            .fill(Color.billixArcadeGold)
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .frame(width: 28, height: 28)

                        Text("$")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("Billix")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("Bill Credit")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                HStack {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
        }
    }
}

// MARK: - Generic Gift Card Visual (Fallback)

struct GenericGiftCardVisual: View {
    let value: String?
    let color: Color
    let type: RewardType

    var body: some View {
        ZStack {
            // Gradient background using accent color
            LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Abstract pattern
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .offset(x: geo.size.width * 0.6, y: -20)

                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: 100, height: 100)
                    .offset(x: -30, y: geo.size.height * 0.5)
            }

            VStack {
                HStack {
                    // Generic icon based on type
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Image(systemName: iconName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Spacer()

                HStack {
                    Text("Gift Card")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    if let value = value {
                        Text(value)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
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
        }
    }
}

// MARK: - Previews

#Preview("Amazon") {
    AmazonGiftCardVisual(value: "$25")
        .frame(width: 200, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("Starbucks") {
    StarbucksGiftCardVisual(value: "$15")
        .frame(width: 200, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("Target") {
    TargetGiftCardVisual(value: "$50")
        .frame(width: 200, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("DoorDash") {
    DoorDashGiftCardVisual(value: "$25")
        .frame(width: 200, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}

#Preview("All Cards") {
    ScrollView(.horizontal) {
        HStack(spacing: 16) {
            AmazonGiftCardVisual(value: "$25")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            StarbucksGiftCardVisual(value: "$15")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            TargetGiftCardVisual(value: "$50")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            DoorDashGiftCardVisual(value: "$25")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            UberGiftCardVisual(value: "$20")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            NetflixGiftCardVisual(value: "$30")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            SpotifyGiftCardVisual(value: "$10")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            BillixGiftCardVisual(value: "$5")
                .frame(width: 180, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding()
    }
    .background(Color.gray.opacity(0.2))
}
