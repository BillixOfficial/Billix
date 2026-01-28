//
//  HeartLostAnimation.swift
//  Billix
//
//  Created by Claude Code
//  Center-screen animation when player loses a heart
//

import SwiftUI

struct HeartLostAnimation: View {

    let onComplete: () -> Void

    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var heartScale: CGFloat = 1.0
    @State private var crackOffset: CGFloat = 0

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                // Broken heart icon
                ZStack {
                    // Heart pieces breaking apart
                    HStack(spacing: 0) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .offset(x: -crackOffset, y: -crackOffset / 2)
                            .rotationEffect(.degrees(-crackOffset / 2))
                            .mask(
                                Rectangle()
                                    .frame(width: 30, height: 60)
                                    .offset(x: -15)
                            )

                        Image(systemName: "heart.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                            .offset(x: crackOffset, y: -crackOffset / 2)
                            .rotationEffect(.degrees(crackOffset / 2))
                            .mask(
                                Rectangle()
                                    .frame(width: 30, height: 60)
                                    .offset(x: 15)
                            )
                    }
                }
                .scaleEffect(heartScale)

                // Text
                Text("HEART LOST")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.red)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            performAnimation()
        }
    }

    private func performAnimation() {
        // Phase 1: Appear (0.0 - 0.2s)
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        // Phase 2: Heart break effect (0.3s - 0.6s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                crackOffset = 20
                heartScale = 1.1
            }
        }

        // Phase 3: Fade out (0.8s - 1.1s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                scale = 0.8
                opacity = 0
            }
        }

        // Complete and dismiss (1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onComplete()
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        HeartLostAnimation {
        }
    }
}
