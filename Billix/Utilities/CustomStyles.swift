import SwiftUI

// MARK: - Custom ViewModifiers using Billix Color Palette

struct GlassMorphicCard: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.billixCreamBeige.opacity(0.7))

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.billixGoldenAmber.opacity(0.3),
                                Color.billixLightPurple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.billixDarkGray.opacity(0.1), radius: 10, x: 0, y: 5)
            .shadow(color: Color.billixGoldenAmber.opacity(0.05), radius: 20, x: 0, y: 10)
    }
}

struct NeumorphicStyle: ViewModifier {
    var isPressed: Bool = false
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.billixCreamBeige)

                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isPressed ? 0.1 : 0.2),
                                    Color.billixDarkGray.opacity(isPressed ? 0.2 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .shadow(
                color: isPressed ? Color.billixDarkGray.opacity(0.15) : Color.white.opacity(0.8),
                radius: isPressed ? 2 : 8,
                x: isPressed ? 2 : -5,
                y: isPressed ? 2 : -5
            )
            .shadow(
                color: isPressed ? Color.white.opacity(0.5) : Color.billixDarkGray.opacity(0.15),
                radius: isPressed ? 2 : 8,
                x: isPressed ? -2 : 5,
                y: isPressed ? -2 : 5
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.billixGoldenAmber.opacity(0.3),
                        Color.billixGold.opacity(0.5),
                        Color.billixGoldenAmber.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 2)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

struct PulsingGlow: ViewModifier {
    @State private var isGlowing = false
    let color: Color

    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? 0.6 : 0.3),
                radius: isGlowing ? 20 : 10,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                ) {
                    isGlowing = true
                }
            }
    }
}

struct FloatingAnimation: ViewModifier {
    @State private var isFloating = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -10 : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    isFloating = true
                }
            }
    }
}

struct ScaleOnTap: ViewModifier {
    @State private var isPressed = false
    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }

                action()
            }
    }
}

// MARK: - View Extensions

extension View {
    func glassMorphic(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassMorphicCard(cornerRadius: cornerRadius))
    }

    func neumorphic(isPressed: Bool = false, cornerRadius: CGFloat = 16) -> some View {
        self.modifier(NeumorphicStyle(isPressed: isPressed, cornerRadius: cornerRadius))
    }

    func shimmer() -> some View {
        self.modifier(ShimmerEffect())
    }

    func pulsingGlow(color: Color = .billixGoldenAmber) -> some View {
        self.modifier(PulsingGlow(color: color))
    }

    func floating(delay: Double = 0) -> some View {
        self.modifier(FloatingAnimation(delay: delay))
    }

    func scaleOnTap(action: @escaping () -> Void) -> some View {
        self.modifier(ScaleOnTap(action: action))
    }
}

// MARK: - Custom Shapes

struct CoinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Create a circular coin
        path.addEllipse(in: rect)

        // Add inner circle for detail
        let innerRect = rect.insetBy(dx: rect.width * 0.15, dy: rect.height * 0.15)
        path.addEllipse(in: innerRect)

        return path
    }
}

struct PiggyBankShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height

        // Simplified piggy bank outline
        // Body (ellipse)
        path.addEllipse(in: CGRect(
            x: width * 0.15,
            y: height * 0.3,
            width: width * 0.7,
            height: height * 0.5
        ))

        // Snout
        path.addEllipse(in: CGRect(
            x: width * 0.75,
            y: height * 0.45,
            width: width * 0.2,
            height: height * 0.2
        ))

        // Ear
        path.move(to: CGPoint(x: width * 0.3, y: height * 0.3))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.35, y: height * 0.25),
            control: CGPoint(x: width * 0.25, y: height * 0.2)
        )

        return path
    }
}

// MARK: - Design System v2 Card Styles

/// Hero card style - Large content cards with dark background and elevated shadow
struct HeroCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
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
}

/// Stat card style - Compact cards for displaying stats with tinted background
struct StatCardStyle: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(accentColor.opacity(DesignSystem.Opacity.backgroundTint))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .stroke(accentColor.opacity(0.3), lineWidth: DesignSystem.Border.thin)
            )
            .shadow(
                color: accentColor.opacity(0.15),
                radius: DesignSystem.Shadow.Light.radius,
                x: 0,
                y: DesignSystem.Shadow.Light.y
            )
    }
}

/// Action button style - Prominent CTAs with accent color background
struct ActionButtonStyle: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color

    init(backgroundColor: Color = .dsPrimaryAccent, foregroundColor: Color = .white) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(foregroundColor)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.standard)
                    .fill(backgroundColor)
            )
            .shadow(
                color: backgroundColor.opacity(0.3),
                radius: DesignSystem.Shadow.Medium.radius,
                x: 0,
                y: DesignSystem.Shadow.Medium.y
            )
    }
}

/// Pill style - Small rounded pills for tags and chips
struct PillStyle: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color

    init(backgroundColor: Color, foregroundColor: Color = .dsTextPrimary) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(foregroundColor)
            .padding(.vertical, DesignSystem.Spacing.xxs / 2)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(backgroundColor)
            )
    }
}

// MARK: - Billix Card Styles (Legacy Support)

/// Standard Billix card style - Updated for dark theme
/// Updated to match Design System v2: dark background, subtle border, refined shadow
struct BillixCardStyle: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let borderColor: Color

    init(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8, borderColor: Color = Color.white.opacity(0.1)) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.borderColor = borderColor
    }

    func body(content: Content) -> some View {
        content
            .background(Color.dsCardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: shadowRadius, x: 0, y: 2)
    }
}

/// Accent card style with colored background and border
struct BillixAccentCardStyle: ViewModifier {
    let backgroundColor: Color
    let accentColor: Color
    let cornerRadius: CGFloat

    init(backgroundColor: Color, accentColor: Color, cornerRadius: CGFloat = 16) {
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(accentColor, lineWidth: 1.5)
            )
            .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

extension View {
    // MARK: - Design System v2 Styles

    /// Applies hero card styling - Large content cards with elevated shadow
    func heroCard() -> some View {
        modifier(HeroCardStyle())
    }

    /// Applies stat card styling with accent color tint
    func statCard(accentColor: Color = .dsPrimaryAccent) -> some View {
        modifier(StatCardStyle(accentColor: accentColor))
    }

    /// Applies action button styling with accent color
    func actionButton(backgroundColor: Color = .dsPrimaryAccent, foregroundColor: Color = .white) -> some View {
        modifier(ActionButtonStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }

    /// Applies pill styling for tags and chips
    func pill(backgroundColor: Color, foregroundColor: Color = .dsTextPrimary) -> some View {
        modifier(PillStyle(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }

    // MARK: - Legacy Billix Styles (Updated for dark theme)

    /// Applies standard Billix card styling (Updated for Design System v2: dark theme)
    func billixCard(cornerRadius: CGFloat = 16, shadowRadius: CGFloat = 8, borderColor: Color = Color.white.opacity(0.1)) -> some View {
        modifier(BillixCardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius, borderColor: borderColor))
    }

    /// Applies accent Billix card styling with colored background
    func billixAccentCard(backgroundColor: Color, accentColor: Color, cornerRadius: CGFloat = 16) -> some View {
        modifier(BillixAccentCardStyle(backgroundColor: backgroundColor, accentColor: accentColor, cornerRadius: cornerRadius))
    }
}
