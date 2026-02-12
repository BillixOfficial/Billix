//
//  WelcomeRewardsSheet.swift
//  Billix
//
//  Created by Claude Code
//  Welcome bonus celebration modal shown after onboarding completion
//

import SwiftUI

struct WelcomeRewardsSheet: View {
    @Binding var isPresented: Bool
    let pointsAwarded: Int
    @State private var showConfetti = false
    @State private var pointsScale: CGFloat = 0.5
    @State private var pointsOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.billixLightGreen
                .ignoresSafeArea()

            // Confetti overlay
            if showConfetti {
                ConfettiView(isActive: true, type: .celebration)
                    .ignoresSafeArea()
            }

            VStack(spacing: 32) {
                Spacer()

                // Title
                VStack(spacing: 12) {
                    Text("🎉")
                        .font(.system(size: 64))

                    Text("Welcome to Billix!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    Text("You've earned your first reward")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)
                }

                // Points display
                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("+\(pointsAwarded)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.billixMoneyGreen)

                        Text("Points")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.billixMediumGreen)
                    }
                    .scaleEffect(pointsScale)
                    .opacity(pointsOpacity)

                    Text("Start earning rewards for taking control of your bills")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.billixMediumGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                )
                .padding(.horizontal, 32)

                Spacer()

                // Continue button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                }) {
                    Text("Continue to App")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.billixMoneyGreen)
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            // Trigger haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            // Start confetti
            withAnimation {
                showConfetti = true
            }

            // Animate points display
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0)) {
                pointsScale = 1.0
                pointsOpacity = 1.0
            }

            // Auto-dismiss after 3 seconds (optional)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                // User can also tap to continue before auto-dismiss
            }
        }
    }
}

// MARK: - Preview

struct WelcomeRewardsSheet_Welcome_Bonus_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeRewardsSheet(isPresented: .constant(true), pointsAwarded: 500)
    }
}

struct WelcomeRewardsSheet_Dark_Mode_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeRewardsSheet(isPresented: .constant(true), pointsAwarded: 500)
        .preferredColorScheme(.dark)
    }
}
