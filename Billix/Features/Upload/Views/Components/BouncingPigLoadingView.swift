//
//  BouncingPigLoadingView.swift
//  Billix
//
//  Created by Claude Code on 12/1/25.
//

import SwiftUI

struct BouncingPigLoadingView: View {
    let message: String

    @State private var bounceOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.3

    private let loadingMessages = [
        "Analyzing your bill...",
        "This usually takes about a minute",
        "Hang tight! We're processing your receipt",
        "Almost there...",
        "Crunching the numbers..."
    ]

    var body: some View {
        ZStack {
            // Greenish gradient background
            LinearGradient(
                colors: [
                    Color.billixLightGreen,
                    Color.billixLightGreen.opacity(0.95),
                    Color(hex: "#E8F5E9")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative circles
            GeometryReader { geo in
                Circle()
                    .fill(Color.billixMoneyGreen.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .offset(x: -50, y: geo.size.height * 0.1)

                Circle()
                    .fill(Color.billixMoneyGreen.opacity(0.05))
                    .frame(width: 150, height: 150)
                    .offset(x: geo.size.width - 80, y: geo.size.height * 0.6)

                Circle()
                    .fill(Color.billixChartBlue.opacity(0.06))
                    .frame(width: 100, height: 100)
                    .offset(x: geo.size.width * 0.3, y: geo.size.height * 0.75)
            }

            VStack(spacing: 32) {
                Spacer()

                // Pig Bouncing on Money Stack with glow effect
                ZStack(alignment: .bottom) {
                    // Pulsing glow behind
                    Circle()
                        .fill(Color.billixMoneyGreen.opacity(pulseOpacity))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                        .offset(y: -20)

                    // Money Stack (stationary) - rendered first (background)
                    Image("money_stack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 110)
                        .offset(y: 20)

                    // Bouncing Pig on top - rendered last (foreground)
                    Image("pig_loading")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .offset(y: bounceOffset - 30)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(scale)
                }
                .frame(height: 200)
                .onAppear {
                    startBounceAnimation()
                    startSubtleRotation()
                    startScalePulse()
                    startGlowPulse()
                }

                // Loading Message Card
                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .multilineTextAlignment(.center)

                    Text("This usually takes about a minute")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)

                    // Progress dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.billixMoneyGreen)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulseOpacity > 0.4 && index == Int(Date().timeIntervalSince1970) % 3 ? 1.3 : 1.0)
                                .animation(.easeInOut(duration: 0.4), value: pulseOpacity)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
                )
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding()
        }
    }

    private func startBounceAnimation() {
        withAnimation(
            .spring(duration: 0.6, bounce: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            bounceOffset = -20  // Bounce UP - negative moves up, pig floats above money
        }
    }

    private func startSubtleRotation() {
        withAnimation(
            .easeInOut(duration: 1.2)
            .repeatForever(autoreverses: true)
        ) {
            rotation = 5
        }
    }

    private func startScalePulse() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            scale = 1.1
        }
    }

    private func startGlowPulse() {
        withAnimation(
            .easeInOut(duration: 1.5)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.6
        }
    }
}

#Preview {
    BouncingPigLoadingView(message: "Analyzing your bill...")
}
