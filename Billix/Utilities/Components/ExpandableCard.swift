import SwiftUI

/// Premium card with tap-to-expand animation - Updated for Design System v2
struct ExpandableCard<Content: View, ExpandedContent: View>: View {
    let content: Content
    let expandedContent: ExpandedContent?
    let backgroundColor: Color
    let borderColor: Color?
    let shadowColor: Color
    let cornerRadius: CGFloat
    let hasExpandedContent: Bool

    @State private var isExpanded = false
    @State private var cardScale: CGFloat = 1.0

    init(
        backgroundColor: Color = .dsCardBackground,
        borderColor: Color? = Color.white.opacity(DesignSystem.Opacity.backgroundTint),
        shadowColor: Color = Color.black.opacity(0.2),
        cornerRadius: CGFloat = DesignSystem.CornerRadius.standard,
        @ViewBuilder content: () -> Content,
        @ViewBuilder expandedContent: () -> ExpandedContent
    ) {
        self.content = content()
        self.expandedContent = expandedContent()
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.cornerRadius = cornerRadius
        self.hasExpandedContent = true
    }

    init(
        backgroundColor: Color = .dsCardBackground,
        borderColor: Color? = Color.white.opacity(DesignSystem.Opacity.backgroundTint),
        shadowColor: Color = Color.black.opacity(0.2),
        cornerRadius: CGFloat = DesignSystem.CornerRadius.standard,
        @ViewBuilder content: () -> Content
    ) where ExpandedContent == EmptyView {
        self.content = content()
        self.expandedContent = nil
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.shadowColor = shadowColor
        self.cornerRadius = cornerRadius
        self.hasExpandedContent = false
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content - always visible
            content
                .contentShape(Rectangle())
                .onTapGesture {
                    if hasExpandedContent {
                        withAnimation(DesignSystem.Animation.spring) {
                            isExpanded.toggle()
                        }

                        // Scale effect - subtle press feedback
                        withAnimation(DesignSystem.Animation.spring) {
                            cardScale = 0.98
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(DesignSystem.Animation.spring) {
                                cardScale = 1.0
                            }
                        }
                    }
                }

            // Expanded content - slides down with animation
            if isExpanded, let expandedContent = expandedContent {
                expandedContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor ?? Color.clear, lineWidth: DesignSystem.Border.thin)
        )
        .shadow(
            color: shadowColor,
            radius: isExpanded ? DesignSystem.Shadow.Heavy.radius : DesignSystem.Shadow.Medium.radius,
            x: 0,
            y: isExpanded ? DesignSystem.Shadow.Heavy.y : DesignSystem.Shadow.Medium.y
        )
        .scaleEffect(cardScale)
    }
}

/// Glass card with blur effect - Updated for Design System v2 (dark theme)
struct GlassCard<Content: View>: View {
    let content: Content
    let tintColor: Color
    let cornerRadius: CGFloat

    init(
        tintColor: Color = .dsPrimaryAccent,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.tintColor = tintColor
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        content
            .background(
                ZStack {
                    // Dark glass effect
                    Color.dsCardBackground.opacity(0.7)

                    // Tint overlay
                    tintColor.opacity(DesignSystem.Opacity.backgroundTint)
                }
            )
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: DesignSystem.Border.thin
                    )
            )
            .shadow(
                color: tintColor.opacity(0.15),
                radius: DesignSystem.Shadow.Medium.radius,
                x: 0,
                y: DesignSystem.Shadow.Medium.y
            )
    }
}

/// Neumorphic card (soft depth effect) - Updated for Design System v2 (dark theme)
struct NeumorphicCard<Content: View>: View {
    let content: Content
    let baseColor: Color
    let cornerRadius: CGFloat
    let padding: CGFloat

    init(
        baseColor: Color = .dsCardBackground,
        cornerRadius: CGFloat = DesignSystem.CornerRadius.large,
        padding: CGFloat = DesignSystem.Spacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.baseColor = baseColor
        self.cornerRadius = cornerRadius
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(baseColor)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 6, y: 6)
                        .shadow(color: Color.white.opacity(0.05), radius: 8, x: -6, y: -6)
                }
            )
    }
}

// Note: Color(hex:) extension is defined in ColorPalette.swift

#Preview {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.sectionSpacing) {
            ExpandableCard(
                backgroundColor: .dsCardBackground,
                shadowColor: .dsPrimaryAccent.opacity(0.2)
            ) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Tap to Expand")
                        .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                        .foregroundColor(.dsTextPrimary)
                    Text("This card has smooth animation")
                        .font(.system(size: DesignSystem.Typography.Size.body))
                        .foregroundColor(.dsTextSecondary)
                }
                .padding()
            } expandedContent: {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Divider()
                        .background(Color.white.opacity(DesignSystem.Opacity.backgroundTint))
                    Text("Hidden content revealed!")
                        .font(.system(size: DesignSystem.Typography.Size.bodyLarge))
                        .foregroundColor(.dsTextPrimary)
                    Text("With smooth Design System spring animation")
                        .font(.system(size: DesignSystem.Typography.Size.caption))
                        .foregroundColor(.dsTextTertiary)
                }
                .padding()
            }

            GlassCard(tintColor: .dsPrimaryAccent) {
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Glass Card")
                        .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                        .foregroundColor(.dsTextPrimary)
                    Text("With dark glass effect")
                        .font(.system(size: DesignSystem.Typography.Size.body))
                        .foregroundColor(.dsTextSecondary)
                }
                .padding()
            }

            NeumorphicCard {
                Text("Neumorphic Design")
                    .font(.system(size: DesignSystem.Typography.Size.h3, weight: .semibold))
                    .foregroundColor(.dsTextPrimary)
            }
        }
        .padding()
    }
    .background(
        LinearGradient(
            colors: [Color.dsBackgroundPrimary, Color.dsBackgroundSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    )
}
