//
//  SegmentedSelector.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

/// A custom segmented control with animated sliding indicator
/// Uses matchedGeometryEffect for smooth selection transitions
struct SegmentedSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String

    var backgroundColor: Color = Color(.systemGray6)
    var selectedColor: Color = .billixMoneyGreen
    var textColor: Color = .primary
    var selectedTextColor: Color = .white
    var cornerRadius: CGFloat = 12
    var height: CGFloat = 44

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = option
                    }
                    // Haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    Text(label(option))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(selection == option ? selectedTextColor : textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: height - 8)
                        .background {
                            if selection == option {
                                RoundedRectangle(cornerRadius: cornerRadius - 2)
                                    .fill(selectedColor)
                                    .matchedGeometryEffect(id: "selector", in: animation)
                                    .shadow(color: selectedColor.opacity(0.3), radius: 4, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(backgroundColor)
        )
    }
}

/// A pill-style selector with gradient indicator
struct PillSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let label: (T) -> String
    let icon: ((T) -> String)?

    @Namespace private var animation

    init(
        options: [T],
        selection: Binding<T>,
        label: @escaping (T) -> String,
        icon: ((T) -> String)? = nil
    ) {
        self.options = options
        self._selection = selection
        self.label = label
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selection = option
                    }
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        if let iconName = icon?(option) {
                            Image(systemName: iconName)
                                .font(.system(size: 14, weight: .medium))
                        }
                        Text(label(option))
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(selection == option ? .white : .billixDarkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        if selection == option {
                            Capsule()
                                .fill(Color.billixMoneyGreen)
                                .matchedGeometryEffect(id: "pill", in: animation)
                                .shadow(color: .billixMoneyGreen.opacity(0.35), radius: 6, y: 3)
                        } else {
                            Capsule()
                                .fill(Color.billixMoneyGreen.opacity(0.1))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// A card-based selector for larger options
struct CardSelector<T: Hashable>: View {
    let options: [T]
    @Binding var selection: T
    let content: (T, Bool) -> AnyView

    var columns: Int = 3
    var spacing: CGFloat = 12

    @Namespace private var animation

    var body: some View {
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns)

        LazyVGrid(columns: gridColumns, spacing: spacing) {
            ForEach(options, id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = option
                    }
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                } label: {
                    content(option, selection == option)
                        .overlay {
                            if selection == option {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.billixMoneyGreen, lineWidth: 3)
                                    .matchedGeometryEffect(id: "cardBorder", in: animation)
                            }
                        }
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
}

/// Button style with opacity change
struct FadeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var frequency: String = "Monthly"
        @State private var category: String = "Utilities"

        var body: some View {
            VStack(spacing: 40) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Segmented Selector")
                        .font(.headline)

                    SegmentedSelector(
                        options: ["Monthly", "Quarterly", "Yearly"],
                        selection: $frequency,
                        label: { $0 }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Pill Selector")
                        .font(.headline)

                    PillSelector(
                        options: ["Utilities", "Telecom", "Insurance"],
                        selection: $category,
                        label: { $0 },
                        icon: { option in
                            switch option {
                            case "Utilities": return "bolt.fill"
                            case "Telecom": return "wifi"
                            case "Insurance": return "shield.fill"
                            default: return "circle"
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    return PreviewWrapper()
}
