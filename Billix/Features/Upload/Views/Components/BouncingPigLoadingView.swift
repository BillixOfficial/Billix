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

    private let loadingMessages = [
        "Analyzing your bill...",
        "This usually takes about a minute",
        "Hang tight! We're processing your receipt",
        "Almost there...",
        "Crunching the numbers..."
    ]

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Pig Bouncing on Money Stack
            ZStack(alignment: .bottom) {
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
                    .offset(y: bounceOffset - 30)  // Closer to money stack
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(scale)
            }
            .frame(height: 200)
            .onAppear {
                startBounceAnimation()
                startSubtleRotation()
                startScalePulse()
            }

            // Loading Message
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Helpful Tip
            Text("This usually takes about a minute")
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
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
}

#Preview {
    BouncingPigLoadingView(message: "Analyzing your bill...")
}
