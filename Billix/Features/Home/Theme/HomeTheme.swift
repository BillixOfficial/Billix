//
//  HomeTheme.swift
//  Billix
//

import SwiftUI

// MARK: - Home Theme

enum HomeTheme {
    // Colors
    static let background = Color(hex: "#F7F9F8")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "#2D3B35")
    static let secondaryText = Color(hex: "#8B9A94")
    static let accent = Color(hex: "#5B8A6B")
    static let accentLight = Color(hex: "#5B8A6B").opacity(0.08)
    static let success = Color(hex: "#4CAF7A")
    static let warning = Color(hex: "#E8A54B")
    static let danger = Color(hex: "#E07A6B")
    static let info = Color(hex: "#5BA4D4")
    static let purple = Color(hex: "#9B7EB8")

    // Spacing
    static let horizontalPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 16

    // Shadow
    static let shadowColor = Color.black.opacity(0.03)
    static let shadowRadius: CGFloat = 8

    // Icon sizes
    static let iconSmall: CGFloat = 14
    static let iconMedium: CGFloat = 18
    static let iconLarge: CGFloat = 24

    // Avatar sizes
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 44
    static let avatarLarge: CGFloat = 56

    // Button heights
    static let buttonHeight: CGFloat = 44
    static let compactButtonHeight: CGFloat = 36
}

// MARK: - Card Style Modifier

struct HomeCardStyle: ViewModifier {
    var hasShadow: Bool = true

    func body(content: Content) -> some View {
        content
            .padding(HomeTheme.cardPadding)
            .background(HomeTheme.cardBackground)
            .cornerRadius(HomeTheme.cornerRadius)
            .shadow(
                color: hasShadow ? HomeTheme.shadowColor : .clear,
                radius: hasShadow ? HomeTheme.shadowRadius : 0,
                x: 0, y: 2
            )
    }
}

// MARK: - View Extensions

extension View {
    func homeCardStyle(shadow: Bool = true) -> some View {
        modifier(HomeCardStyle(hasShadow: shadow))
    }

    func sectionHeader() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(HomeTheme.secondaryText)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    func homeTitle() -> some View {
        self
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(HomeTheme.primaryText)
    }

    func homeSubtitle() -> some View {
        self
            .font(.system(size: 13))
            .foregroundColor(HomeTheme.secondaryText)
    }

    func homeCaption() -> some View {
        self
            .font(.system(size: 11))
            .foregroundColor(HomeTheme.secondaryText)
    }
}

// MARK: - Haptic Helper

func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
    UIImpactFeedbackGenerator(style: style).impactOccurred()
}
