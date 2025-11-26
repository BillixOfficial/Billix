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
