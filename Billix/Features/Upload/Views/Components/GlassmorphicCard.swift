//
//  GlassmorphicCard.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// A reusable glassmorphic card container with frosted glass effect
/// Uses SwiftUI's native Material for the blur effect
struct GlassmorphicCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat
    var material: Material
    var borderGradient: LinearGradient?

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 20,
        material: Material = .ultraThinMaterial,
        borderGradient: LinearGradient? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.material = material
        self.borderGradient = borderGradient
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Frosted glass background
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(material)

                    // White overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.white.opacity(0.3))

                    // Optional gradient border
                    if let gradient = borderGradient {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(gradient, lineWidth: 1.5)
                    } else {
                        // Default subtle white border
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                    }
                }
            )
            // Multi-layer shadow for depth
            .shadow(color: .black.opacity(0.08), radius: shadowRadius, x: 0, y: 10)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}

/// A solid white card variant for cleaner backgrounds
struct SolidCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 15,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
            )
            .shadow(color: .black.opacity(0.06), radius: shadowRadius, x: 0, y: 8)
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

/// A solid color card for primary actions (replaces GradientCard)
struct AccentCard<Content: View>: View {
    let content: Content
    var color: Color
    var cornerRadius: CGFloat
    var padding: CGFloat

    init(
        color: Color = .billixMoneyGreen,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(color)
            )
            // Colored shadow for brand reinforcement
            .shadow(color: color.opacity(0.3), radius: 12, x: 0, y: 6)
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

/// Legacy GradientCard for backwards compatibility - prefer AccentCard
struct GradientCard<Content: View>: View {
    let content: Content
    var gradient: LinearGradient
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowColor: Color

    init(
        gradient: LinearGradient,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowColor: Color = .black,
        @ViewBuilder content: () -> Content
    ) {
        self.gradient = gradient
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowColor = shadowColor
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(gradient)
            )
            .shadow(color: shadowColor.opacity(0.2), radius: 15, x: 0, y: 8)
            .shadow(color: shadowColor.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Solid Accent Colors (Recommended)

extension Color {
    // Primary accent - solid green
    static let accentPrimary = Color.billixMoneyGreen

    // Secondary accent - solid blue
    static let accentSecondary = Color(red: 0.2, green: 0.5, blue: 0.9)

    // Status colors - solid
    static let statusOverpaying = Color(red: 0.9, green: 0.3, blue: 0.3)  // Solid red
    static let statusUnderpaying = Color.billixMoneyGreen                  // Solid green
    static let statusNeutral = Color(red: 0.3, green: 0.5, blue: 0.9)     // Solid blue

    // Category accent colors - solid
    static let categoryUtilities = Color.billixMoneyGreen                  // Green
    static let categoryTelecom = Color(red: 0.2, green: 0.5, blue: 0.9)   // Blue
    static let categoryInsurance = Color(red: 0.6, green: 0.4, blue: 0.8) // Purple

    // Button colors - solid
    static let buttonCamera = Color(red: 0.2, green: 0.5, blue: 0.9)      // Solid blue
    static let buttonGallery = Color(red: 0.2, green: 0.7, blue: 0.7)     // Solid teal
    static let buttonDocument = Color(red: 0.6, green: 0.4, blue: 0.8)    // Solid purple
}

// MARK: - Legacy Gradients (Deprecated - use solid colors)

extension LinearGradient {
    /// DEPRECATED: Use Color.accentPrimary instead
    static let billixPrimary = LinearGradient(
        colors: [Color.billixMoneyGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// DEPRECATED: Use Color.accentSecondary instead
    static let billixSecondary = LinearGradient(
        colors: [Color.accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// DEPRECATED: Use Color.statusOverpaying instead
    static let billixWarning = LinearGradient(
        colors: [Color.statusOverpaying],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// DEPRECATED: Use Color.statusUnderpaying instead
    static let billixSuccess = LinearGradient(
        colors: [Color.statusUnderpaying],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// DEPRECATED: Use Color.categoryInsurance instead
    static let billixPurple = LinearGradient(
        colors: [Color.categoryInsurance],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Subtle glass border - keep as subtle effect
    static let glassBorder = LinearGradient(
        colors: [Color.white.opacity(0.6), Color.white.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.billixLightGreen
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassmorphicCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Glassmorphic Card")
                        .font(.headline)
                    Text("With frosted glass effect")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            SolidCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Solid Card")
                        .font(.headline)
                    Text("Clean white background")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            AccentCard(color: .accentPrimary) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                    Text("Accent Card")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundColor(.white)
            }
        }
        .padding()
    }
}
