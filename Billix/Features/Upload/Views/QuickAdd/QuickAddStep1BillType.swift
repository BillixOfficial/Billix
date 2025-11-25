//
//  QuickAddStep1BillType.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep1BillType: View {
    @ObservedObject var viewModel: QuickAddViewModel
    var namespace: Namespace.ID

    @State private var appeared = false

    // Group bill types by category with solid accent colors
    private var groupedBillTypes: [(category: String, icon: String, color: Color, types: [BillType])] {
        let utilities = viewModel.billTypes.filter { $0.category == "Utilities" }
        let telecom = viewModel.billTypes.filter { $0.category == "Telecom" }
        let insurance = viewModel.billTypes.filter { $0.category == "Insurance" }

        return [
            (category: "Utilities", icon: "bolt.fill", color: .categoryUtilities, types: utilities),
            (category: "Telecom", icon: "wifi", color: .categoryTelecom, types: telecom),
            (category: "Insurance", icon: "shield.fill", color: .categoryInsurance, types: insurance)
        ].filter { !$0.types.isEmpty }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("What bill are you adding?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    Text("We'll compare it to your area average")
                        .font(.system(size: 15))
                        .foregroundColor(.billixMediumGreen)
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else {
                    // Categorized bill types
                    VStack(spacing: 20) {
                        ForEach(Array(groupedBillTypes.enumerated()), id: \.element.category) { index, group in
                            CategorySection(
                                category: group.category,
                                icon: group.icon,
                                color: group.color,
                                billTypes: group.types,
                                selectedBillType: viewModel.selectedBillType,
                                namespace: namespace,
                                onSelect: { billType in
                                    selectBillType(billType)
                                }
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 30)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1 + 0.2),
                                value: appeared
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    // MARK: - Helper Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading bill types...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Actions

    private func selectBillType(_ billType: BillType) {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Select and advance
        viewModel.selectBillType(billType)
    }
}

// MARK: - Category Section

struct CategorySection: View {
    let category: String
    let icon: String
    let color: Color  // Solid color instead of gradient
    let billTypes: [BillType]
    let selectedBillType: BillType?
    var namespace: Namespace.ID
    let onSelect: (BillType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header with solid accent color
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)

                Text(category.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.billixMediumGreen)
                    .tracking(1.2)
            }
            .padding(.leading, 4)

            // Bill type cards with solid card styling
            SolidCard(
                cornerRadius: 20,
                padding: 12,
                shadowRadius: 12
            ) {
                HStack(spacing: 8) {
                    ForEach(billTypes) { billType in
                        BillTypeButton(
                            billType: billType,
                            isSelected: selectedBillType?.id == billType.id,
                            color: color,
                            namespace: namespace,
                            onTap: { onSelect(billType) }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Bill Type Button

struct BillTypeButton: View {
    let billType: BillType
    let isSelected: Bool
    let color: Color  // Solid color instead of gradient
    var namespace: Namespace.ID
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Icon with solid color fill
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(color)
                            .matchedGeometryEffect(id: "iconBg-\(billType.id)", in: namespace)
                            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
                    } else {
                        Circle()
                            .fill(Color.billixMoneyGreen.opacity(0.1))
                    }

                    Image(systemName: billType.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .billixMoneyGreen)
                }
                .frame(width: 52, height: 52)

                // Label
                Text(billType.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? .billixDarkGreen : .billixMediumGreen)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? color.opacity(0.08) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var viewModel = QuickAddViewModel()
        @Namespace private var namespace

        var body: some View {
            ZStack {
                Color.billixLightGreen.ignoresSafeArea()
                QuickAddStep1BillType(viewModel: viewModel, namespace: namespace)
            }
            .onAppear {
                viewModel.onAppear()
            }
        }
    }

    return PreviewWrapper()
}
