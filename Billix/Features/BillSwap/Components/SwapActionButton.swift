//
//  SwapActionButton.swift
//  Billix
//
//  Reusable action button component for BillSwap
//

import SwiftUI

struct SwapActionButton: View {
    let title: String
    var icon: String?
    var style: ButtonStyleType = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void

    enum ButtonStyleType {
        case primary
        case secondary
        case success
        case danger
        case outline

        var backgroundColor: Color {
            switch self {
            case .primary: return .billixDarkTeal
            case .secondary: return .secondary
            case .success: return .billixMoneyGreen
            case .danger: return .red
            case .outline: return .clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .success, .danger: return .white
            case .outline: return .billixDarkTeal
            }
        }

        var borderColor: Color? {
            switch self {
            case .outline: return .billixDarkTeal
            default: return nil
            }
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor ?? .clear, lineWidth: style.borderColor != nil ? 2 : 0)
            )
        }
        .disabled(isLoading || isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
}

// MARK: - Compact Action Button

struct CompactActionButton: View {
    let title: String
    var icon: String?
    var color: Color = .billixDarkTeal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
    }
}

// MARK: - Icon Button

struct SwapIconButton: View {
    let icon: String
    var size: CGFloat = 44
    var color: Color = .billixDarkTeal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4))
                .frame(width: size, height: size)
                .background(color.opacity(0.1))
                .foregroundColor(color)
                .cornerRadius(size / 4)
        }
    }
}

// MARK: - Preview

#Preview("Swap Action Buttons") {
    VStack(spacing: 16) {
        SwapActionButton(title: "Accept Swap", icon: "hand.thumbsup.fill", style: .primary) { }

        SwapActionButton(title: "Pay $1.99", icon: "creditcard.fill", style: .success) { }

        SwapActionButton(title: "Loading...", style: .primary, isLoading: true) { }

        SwapActionButton(title: "Disabled", style: .primary, isDisabled: true) { }

        SwapActionButton(title: "Cancel", style: .outline) { }

        SwapActionButton(title: "Report Issue", icon: "exclamationmark.triangle", style: .danger) { }

        HStack(spacing: 12) {
            CompactActionButton(title: "Accept", icon: "checkmark") { }
            CompactActionButton(title: "Decline", icon: "xmark", color: .red) { }
        }

        HStack(spacing: 12) {
            SwapIconButton(icon: "message.fill") { }
            SwapIconButton(icon: "phone.fill", color: .green) { }
            SwapIconButton(icon: "ellipsis", color: .secondary) { }
        }
    }
    .padding()
}
