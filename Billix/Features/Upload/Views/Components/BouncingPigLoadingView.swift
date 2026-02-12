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
    @State private var dotIndex: Int = 0


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

            // Decorative circles (static bubbles)
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

                // Pig Bouncing on Money Stack
                ZStack(alignment: .bottom) {
                    // Static glow behind
                    Circle()
                        .fill(Color.billixMoneyGreen.opacity(0.4))
                        .frame(width: 160, height: 160)
                        .blur(radius: 30)
                        .offset(y: -20)

                    // Money Stack (stationary)
                    Image("money_stack")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 110)
                        .offset(y: 20)

                    // Bouncing Pig ONLY - animation scoped to just this element
                    Image("pig_loading")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90, height: 90)
                        .offset(y: bounceOffset - 57)
                        .animation(
                            .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                            value: bounceOffset
                        )
                }
                .frame(height: 200)
                .onAppear {
                    bounceOffset = -15
                    startDotAnimation()
                }

                // Loading Message Card (static)
                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.billixDarkGreen)
                        .multilineTextAlignment(.center)

                    Text("This usually takes about a minute")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)

                    // Progress dots (simple opacity animation)
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.billixMoneyGreen)
                                .frame(width: 8, height: 8)
                                .opacity(dotIndex == index ? 1.0 : 0.4)
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

    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotIndex = (dotIndex + 1) % 3
        }
    }
}

struct BouncingPigLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        BouncingPigLoadingView(message: "Analyzing your bill...")
    }
}
