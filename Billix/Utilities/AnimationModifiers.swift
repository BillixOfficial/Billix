//
//  AnimationModifiers.swift
//  Billix
//
//  Created by Claude Code
//  Reusable animation modifiers for consistent UX
//

import SwiftUI

// MARK: - Staggered Appearance

struct StaggeredAppearance: ViewModifier {
    let index: Int
    let appeared: Bool

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                .delay(Double(index) * 0.08),
                value: appeared
            )
    }
}

extension View {
    /// Adds staggered entrance animation to views
    /// - Parameters:
    ///   - index: The index of the view in a list (determines delay)
    ///   - appeared: Whether the view should be visible
    /// - Returns: Modified view with staggered animation
    func staggeredAppearance(index: Int, appeared: Bool) -> some View {
        modifier(StaggeredAppearance(index: index, appeared: appeared))
    }
}

// MARK: - Interactive Scale

struct InteractiveScale: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

extension View {
    /// Adds interactive press state with haptic feedback
    /// Scales down to 0.97 when pressed
    /// - Returns: Modified view with interactive scaling
    func interactiveScale() -> some View {
        modifier(InteractiveScale())
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .white.opacity(0),
                            .white.opacity(0.3),
                            .white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                }
                .mask(content)
            )
            .onAppear {
                isAnimating = true
                withAnimation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false)
                ) {
                    if isAnimating {
                        phase = 1
                    }
                }
            }
            .onDisappear {
                isAnimating = false
                phase = 0
            }
    }
}

extension View {
    /// Adds a shimmer effect that sweeps across the view
    /// - Returns: Modified view with shimmer animation
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Bounce Animation

struct BounceAnimation: ViewModifier {
    @State private var isAnimating = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .onAppear {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.6)
                    .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
            }
            .onDisappear {
                isAnimating = false
            }
    }
}

extension View {
    /// Adds a subtle bounce animation that repeats
    /// - Returns: Modified view with bouncing animation
    func bounceAnimation() -> some View {
        modifier(BounceAnimation())
    }
}

// MARK: - Smooth Opacity Transition

struct SmoothOpacity: ViewModifier {
    let isVisible: Bool
    let duration: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: duration), value: isVisible)
    }
}

extension View {
    /// Adds smooth opacity transition
    /// - Parameters:
    ///   - isVisible: Whether the view should be visible
    ///   - duration: Animation duration (default: 0.3)
    /// - Returns: Modified view with opacity animation
    func smoothOpacity(isVisible: Bool, duration: Double = 0.3) -> some View {
        modifier(SmoothOpacity(isVisible: isVisible, duration: duration))
    }
}
