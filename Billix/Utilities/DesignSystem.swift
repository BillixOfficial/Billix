//
//  DesignSystem.swift
//  Billix
//
//  Design system tokens for consistent styling across the app
//

import SwiftUI

/// Central design system providing spacing, typography, corner radius, shadows, and animation tokens
struct DesignSystem {

    // MARK: - Spacing Scale (8pt Grid System)

    struct Spacing {
        static let xxxs: CGFloat = 4
        static let xxs: CGFloat = 8
        static let xs: CGFloat = 12
        static let sm: CGFloat = 16
        static let md: CGFloat = 20
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
        static let huge: CGFloat = 64

        /// Standard screen edge padding
        static let screenEdge: CGFloat = 20

        /// Standard card internal padding
        static let cardPadding: CGFloat = 16

        /// Spacing between major sections
        static let sectionSpacing: CGFloat = 24
    }

    // MARK: - Typography Scale

    struct Typography {
        /// 48pt bold rounded - Hero numbers and display text
        static func display(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 48, weight: .bold, design: .rounded))
        }

        /// 32pt bold - Major section headers
        static func h1(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 32, weight: .bold, design: .rounded))
        }

        /// 24pt semibold - Card titles and subsection headers
        static func h2(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 24, weight: .semibold))
        }

        /// 20pt semibold - Subsection headers
        static func h3(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 20, weight: .semibold))
        }

        /// 16pt regular - Primary body content
        static func bodyLarge(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 16, weight: .regular))
        }

        /// 14pt regular - Secondary body content
        static func body(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 14, weight: .regular))
        }

        /// 12pt medium - Labels and meta information
        static func caption(_ text: String) -> some View {
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }

        // Font size constants for direct use
        struct Size {
            static let display: CGFloat = 48
            static let h1: CGFloat = 32
            static let h2: CGFloat = 24
            static let h3: CGFloat = 20
            static let bodyLarge: CGFloat = 16
            static let body: CGFloat = 14
            static let caption: CGFloat = 12
        }

        // Font weight constants
        struct Weight {
            static let bold: Font.Weight = .bold
            static let semibold: Font.Weight = .semibold
            static let medium: Font.Weight = .medium
            static let regular: Font.Weight = .regular
        }
    }

    // MARK: - Corner Radius System

    struct CornerRadius {
        /// 8px - Small elements, pills, chips
        static let small: CGFloat = 8

        /// 16px - Standard cards and components
        static let standard: CGFloat = 16

        /// 24px - Large cards and hero content
        static let large: CGFloat = 24
    }

    // MARK: - Shadow System

    struct Shadow {
        /// Light shadow for subtle elevation
        static func light() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }

        /// Medium shadow for cards
        static func medium() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }

        /// Heavy shadow for elevated content
        static func heavy() -> some View {
            EmptyView()
                .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
        }

        // Shadow parameters for direct use
        struct Light {
            static let color: Color = Color.black.opacity(0.05)
            static let radius: CGFloat = 4
            static let y: CGFloat = 2
        }

        struct Medium {
            static let color: Color = Color.black.opacity(0.1)
            static let radius: CGFloat = 8
            static let y: CGFloat = 4
        }

        struct Heavy {
            static let color: Color = Color.black.opacity(0.15)
            static let radius: CGFloat = 16
            static let y: CGFloat = 8
        }
    }

    // MARK: - Animation Timing

    struct Animation {
        /// Quick animations - 0.2s
        static let quick: Double = 0.2

        /// Standard animations - 0.3s
        static let standard: Double = 0.3

        /// Slow animations - 0.5s
        static let slow: Double = 0.5

        /// Standard spring animation with damping
        static let spring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.8)

        /// Smooth spring for gentle movements
        static let smoothSpring: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.9)

        /// Bouncy spring for playful interactions
        static let bouncySpring: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.6)
    }

    // MARK: - Opacity Levels (for text hierarchy)

    struct Opacity {
        /// Primary text - 100%
        static let primary: Double = 1.0

        /// Secondary text - 87%
        static let secondary: Double = 0.87

        /// Tertiary text - 60%
        static let tertiary: Double = 0.6

        /// Disabled text - 38%
        static let disabled: Double = 0.38

        /// Subtle backgrounds - 5%
        static let backgroundSubtle: Double = 0.05

        /// Tinted backgrounds - 10%
        static let backgroundTint: Double = 0.1

        /// Prominent backgrounds - 20%
        static let backgroundProminent: Double = 0.2
    }

    // MARK: - Border Widths

    struct Border {
        static let thin: CGFloat = 1
        static let medium: CGFloat = 1.5
        static let thick: CGFloat = 2
    }
}

// MARK: - Convenience View Modifiers

extension View {
    /// Apply standard card styling with design system tokens
    func dsCard(cornerRadius: CGFloat = DesignSystem.CornerRadius.standard) -> some View {
        self
            .background(Color.dsCardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(DesignSystem.Opacity.backgroundTint), lineWidth: DesignSystem.Border.thin)
            )
            .shadow(
                color: DesignSystem.Shadow.Medium.color,
                radius: DesignSystem.Shadow.Medium.radius,
                x: 0,
                y: DesignSystem.Shadow.Medium.y
            )
    }

    /// Apply hero card styling with large corner radius
    func dsHeroCard() -> some View {
        self
            .background(Color.dsCardBackground)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(Color.white.opacity(DesignSystem.Opacity.backgroundTint), lineWidth: DesignSystem.Border.thin)
            )
            .shadow(
                color: DesignSystem.Shadow.Heavy.color,
                radius: DesignSystem.Shadow.Heavy.radius,
                x: 0,
                y: DesignSystem.Shadow.Heavy.y
            )
    }

    /// Apply standard padding (screen edge)
    func dsScreenPadding() -> some View {
        self.padding(.horizontal, DesignSystem.Spacing.screenEdge)
    }

    /// Apply card internal padding
    func dsCardPadding() -> some View {
        self.padding(DesignSystem.Spacing.cardPadding)
    }
}
