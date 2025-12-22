//
//  GeoGameHowToPlayView.swift
//  Billix
//
//  Created by Claude Code
//  Tutorial screen shown before starting GeoGame
//  Based on industry best practices for game onboarding
//

import SwiftUI

struct GeoGameHowToPlayView: View {

    let onStart: () -> Void
    let onSkip: () -> Void
    let onSkipAndDontShowAgain: () -> Void
    let onPageChanged: (Int) -> Void
    let isLoading: Bool
    let isManualView: Bool  // NEW: When true, shows X to close instead of skip options

    @State private var currentPage = 0
    @State private var appeared = false
    @State private var showSkipConfirmation = false

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "map.fill",
            iconColor: .blue,
            title: "Find the Landmark",
            description: "Explore the map and tap the correct landmark location",
            tip: "Use drag to explore • Rotate to look around"
        ),
        TutorialPage(
            icon: "dollarsign.circle.fill",
            iconColor: .green,
            title: "Guess the Price",
            description: "Estimate prices for everyday items in that location",
            tip: "Within 25% = Safe • Closer = More points"
        ),
        TutorialPage(
            icon: "flame.fill",
            iconColor: .orange,
            title: "Build Combos",
            description: "Answer correctly to build streaks and earn multipliers",
            tip: "2+ correct = Combo bonus • 6+ = 2X points!"
        ),
        TutorialPage(
            icon: "heart.fill",
            iconColor: .red,
            title: "Protect Your Hearts",
            description: "You have 3 hearts. Wrong answers cost a heart!",
            tip: "Game over at 0 hearts • Play smart!"
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button (only show for automatic tutorial, not manual view)
                if !isManualView {
                    HStack {
                        Spacer()
                        Button(action: {
                            showSkipConfirmation = true
                        }) {
                            Text("Skip")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                        }
                        .accessibilityLabel("Skip tutorial")
                        .accessibilityHint("Opens options to skip now or permanently dismiss tutorial")
                        .disabled(isLoading)
                    }
                    .padding(.top, 56)
                    .padding(.trailing, 16)
                    .opacity(appeared ? 1 : 0)
                } else {
                    // Close button for manual view
                    HStack {
                        Spacer()
                        Button(action: {
                            onSkip()  // Just close
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Close tutorial")
                    }
                    .padding(.top, 56)
                    .padding(.trailing, 16)
                    .opacity(appeared ? 1 : 0)
                }

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        TutorialPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 500)
                .opacity(appeared ? 1 : 0)
                .onChange(of: currentPage) { newPage in
                    onPageChanged(newPage)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Tutorial page \(currentPage + 1) of \(pages.count)")

                // Page indicators (custom)
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                    }
                }
                .padding(.vertical, 24)
                .opacity(appeared ? 1 : 0)

                // Bottom button
                if currentPage == pages.count - 1 {
                    Button(action: {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        onStart()
                    }) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("LET'S PLAY!")
                                Image(systemName: "arrow.right.circle.fill")
                            }
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [.billixArcadeGold, .billixPrizeOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .billixArcadeGold.opacity(0.5), radius: 20, y: 10)
                    }
                    .disabled(isLoading)
                    .accessibilityLabel("Start playing Price Guessr")
                    .accessibilityHint("Closes tutorial and begins the game")
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentPage += 1
                        }
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                    }) {
                        HStack(spacing: 12) {
                            Text("Next")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .accessibilityLabel("Next page")
                    .accessibilityHint("Advances to page \(currentPage + 2) of \(pages.count)")
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer(minLength: 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
        .confirmationDialog("Skip Tutorial?", isPresented: $showSkipConfirmation, titleVisibility: .visible) {
            Button("Skip for Now") {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                onSkip()
            }

            Button("Don't Show Again", role: .destructive) {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
                onSkipAndDontShowAgain()
            }

            Button("Cancel", role: .cancel) {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        } message: {
            Text("You can always access the tutorial from settings if you need it later.")
        }
    }
}

// MARK: - Tutorial Page View

struct TutorialPageView: View {
    let page: TutorialPage

    @State private var iconScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [page.iconColor.opacity(0.4), page.iconColor.opacity(0.1), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 20)

                // Icon circle background
                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 140, height: 140)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 70))
                    .foregroundColor(page.iconColor)
                    .accessibilityLabel("\(page.title) icon")
            }
            .scaleEffect(iconScale)
            .accessibilityHidden(true)

            // Content
            VStack(spacing: 16) {
                // Title
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // Description
                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 40)

                // Tip box
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.billixArcadeGold)

                    Text(page.tip)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.billixArcadeGold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.billixArcadeGold.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(Color.billixArcadeGold.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.top, 8)
            }
            .opacity(textOpacity)
        }
        .padding(.horizontal, 24)
        .onAppear {
            // Staggered animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                iconScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - Tutorial Page Model

struct TutorialPage {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let tip: String
}

#Preview {
    GeoGameHowToPlayView(
        onStart: {
            print("Start game")
        },
        onSkip: {
            print("Skip tutorial")
        },
        onSkipAndDontShowAgain: {
            print("Skip and don't show again")
        },
        onPageChanged: { pageNumber in
            print("Page changed to: \(pageNumber)")
        },
        isLoading: false,
        isManualView: false
    )
}
