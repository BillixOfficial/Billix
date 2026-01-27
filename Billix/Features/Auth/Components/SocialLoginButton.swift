//
//  SocialLoginButton.swift
//  Billix
//
//  Reusable circular button for social login providers
//

import SwiftUI

struct SocialLoginButton: View {
    enum Provider {
        case google

        var iconName: String {
            switch self {
            case .google: return "g.circle.fill"
            }
        }

        var backgroundColor: Color {
            switch self {
            case .google: return Color.white
            }
        }

        var iconColor: Color {
            switch self {
            case .google: return Color(hex: "#4285F4")
            }
        }

        var borderColor: Color {
            switch self {
            case .google: return Color.gray.opacity(0.3)
            }
        }

        var label: String {
            switch self {
            case .google: return "Google"
            }
        }
    }

    let provider: Provider
    let action: () -> Void
    let isLoading: Bool

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(provider.backgroundColor)
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(provider.borderColor, lineWidth: 1)
                        )

                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: provider.iconColor))
                    } else {
                        Image(systemName: provider.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(provider.iconColor)
                    }
                }

                Text(provider.label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#5A6B64"))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .opacity(isLoading ? 0.7 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SocialLoginButton(
            provider: .google,
            action: { print("Google tapped") },
            isLoading: false
        )

        SocialLoginButton(
            provider: .google,
            action: { },
            isLoading: true
        )
    }
    .padding()
    .background(Color(hex: "#F7F9F8"))
}
