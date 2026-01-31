//
//  ProfileComponents.swift
//  Billix
//
//  Reusable UI components for the Profile feature
//

import SwiftUI

// MARK: - Profile Card Component

struct ProfileCard<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title = title {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(hex: "#9CA3AF"))
                    .tracking(1.2)
            }

            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Support Row View

struct SupportRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    private let darkTextColor = Color(hex: "#2D3436")
    private let grayTextColor = Color(hex: "#636E72")

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(darkTextColor)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(grayTextColor)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(grayTextColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Account Row View

struct AccountRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    var showChevron: Bool = true

    private let darkTextColor = Color(hex: "#2D3436")
    private let grayTextColor = Color(hex: "#636E72")

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(darkTextColor)

            Spacer()

            if let value = value {
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(grayTextColor)
                    .lineLimit(1)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "#B2BEC3"))
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Profile Settings Row Link

struct ProfileSettingsRowLink: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?

    private let darkTextColor = Color(hex: "#2D3436")
    private let grayTextColor = Color(hex: "#636E72")

    var body: some View {
        Button {
            // Navigate to edit
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.10))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(darkTextColor)

                Spacer()

                if let value = value {
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(grayTextColor)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "#CBD5E0"))
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Profile Settings Toggle Row

struct ProfileSettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool
    let tintColor: Color

    private let darkTextColor = Color(hex: "#2D3436")

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(darkTextColor)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor)
                .scaleEffect(0.9)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - FAQ Item View

struct FAQItemView: View {
    let icon: String
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#4A7C59").opacity(0.1))
                            .frame(width: 36, height: 36)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "#4A7C59"))
                    }

                    Text(question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "#2D3436"))
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#9CA3AF"))
                }
                .padding(14)
            }

            if isExpanded {
                Text(answer)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "#636E72"))
                    .lineSpacing(4)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                    .padding(.leading, 48)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#4A7C59"))
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15))
                .foregroundColor(Color(hex: "#2D3436"))

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "#4A7C59"))
        }
    }
}

// MARK: - Tip Row

struct TipRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#4A7C59"))
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "#636E72"))
        }
    }
}
