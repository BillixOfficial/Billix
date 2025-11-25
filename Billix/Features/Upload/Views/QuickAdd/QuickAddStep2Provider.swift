//
//  QuickAddStep2Provider.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct QuickAddStep2Provider: View {
    @ObservedObject var viewModel: QuickAddViewModel
    var namespace: Namespace.ID
    var onSwitchToFullAnalysis: (() -> Void)?

    @State private var appeared = false
    @FocusState private var isZipFocused: Bool

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where do you live?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.billixDarkGreen)

                    Text("We'll show your options")
                        .font(.system(size: 15))
                        .foregroundColor(.billixMediumGreen)
                }
                .padding(.horizontal, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                // ZIP Code Input Card
                zipCodeSection
                    .padding(.horizontal, 20)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 30)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                // Providers Section
                if viewModel.isLoading {
                    loadingProvidersView
                        .padding(.horizontal, 20)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                        .padding(.horizontal, 20)
                } else if !viewModel.providers.isEmpty {
                    providersSection
                        .padding(.horizontal, 20)
                } else if viewModel.zipCode.count == 5 {
                    // Empty state - no providers found for this ZIP
                    emptyProvidersView
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
            // Only auto-focus ZIP input if it's empty
            if viewModel.zipCode.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isZipFocused = true
                }
            }
        }
    }

    // MARK: - ZIP Code Section

    private var zipCodeSection: some View {
        SolidCard(cornerRadius: 20, padding: 20, shadowRadius: 12) {
            VStack(spacing: 16) {
                // Icon and label with solid accent color
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.billixMoneyGreen)
                            .frame(width: 44, height: 44)
                            .shadow(color: .billixMoneyGreen.opacity(0.3), radius: 6, x: 0, y: 3)

                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ZIP Code")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)

                        Text("Enter your 5-digit ZIP")
                            .font(.system(size: 12))
                            .foregroundColor(.billixMediumGreen)
                    }

                    Spacer()

                    // Clear button or checkmark
                    if viewModel.zipCode.count == 5 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.billixMoneyGreen)
                            .transition(.scale.combined(with: .opacity))
                    } else if !viewModel.zipCode.isEmpty {
                        Button {
                            viewModel.zipCode = ""
                            isZipFocused = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.billixMediumGreen)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                // ZIP Input boxes
                ZipCodeInput(
                    zipCode: $viewModel.zipCode,
                    isFocused: $isZipFocused,
                    onComplete: {
                        Task {
                            await viewModel.loadProviders()
                        }
                    }
                )
            }
        }
    }

    // MARK: - Providers Section

    private var providersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.billixMoneyGreen)

                Text("Select your provider")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.2), value: appeared)

            // Provider list
            VStack(spacing: 12) {
                ForEach(Array(viewModel.providers.enumerated()), id: \.element.id) { index, provider in
                    ProviderCard(
                        provider: provider,
                        isSelected: viewModel.selectedProvider?.id == provider.id,
                        namespace: namespace,
                        onSelect: {
                            selectProvider(provider)
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.8)
                        .delay(Double(index) * 0.08),
                        value: viewModel.providers.count
                    )
                }
            }
        }
    }

    // MARK: - Loading View

    private var loadingProvidersView: some View {
        VStack(spacing: 16) {
            // Shimmer loading cards
            ForEach(0..<3, id: \.self) { index in
                ShimmerCard()
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.2),
                        value: viewModel.isLoading
                    )
            }
        }
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

    // MARK: - Empty Providers View

    private var emptyProvidersView: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.billixLightGreen)
                    .frame(width: 80, height: 80)

                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 36))
                    .foregroundColor(.billixMediumGreen)
            }

            // Message
            VStack(spacing: 8) {
                Text("No Providers Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.billixDarkGreen)

                Text("We don't have your provider in our database yet. Try Full Analysis to scan your bill and help us add it!")
                    .font(.system(size: 14))
                    .foregroundColor(.billixMediumGreen)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            // Full Analysis Button
            Button {
                onSwitchToFullAnalysis?()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Try Full Analysis Instead")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.billixChartBlue)
                )
                .shadow(color: Color.billixChartBlue.opacity(0.3), radius: 8, y: 4)
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.98))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
        )
    }

    // MARK: - Actions

    private func selectProvider(_ provider: BillProvider) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        viewModel.selectProvider(provider)
    }
}

// MARK: - ZIP Code Input Component

struct ZipCodeInput: View {
    @Binding var zipCode: String
    var isFocused: FocusState<Bool>.Binding
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                ZipDigitBox(
                    digit: getDigit(at: index),
                    isActive: zipCode.count == index && isFocused.wrappedValue,
                    isFilled: index < zipCode.count
                )
            }
        }
        .background(
            // Hidden text field for actual input
            TextField("", text: $zipCode)
                .keyboardType(.numberPad)
                .focused(isFocused)
                .opacity(0)
                .onChange(of: zipCode) { _, newValue in
                    // Limit to 5 digits and numbers only
                    let filtered = newValue.filter { $0.isNumber }
                    if filtered.count > 5 {
                        zipCode = String(filtered.prefix(5))
                    } else if filtered != newValue {
                        zipCode = filtered
                    }

                    // Trigger completion and dismiss keyboard when 5 digits entered
                    if zipCode.count == 5 {
                        isFocused.wrappedValue = false
                        onComplete()
                    }
                }
        )
        .onTapGesture {
            isFocused.wrappedValue = true
        }
    }

    private func getDigit(at index: Int) -> String {
        guard index < zipCode.count else { return "" }
        let startIndex = zipCode.index(zipCode.startIndex, offsetBy: index)
        return String(zipCode[startIndex])
    }
}

struct ZipDigitBox: View {
    let digit: String
    let isActive: Bool
    let isFilled: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isFilled ? Color.billixMoneyGreen.opacity(0.1) : Color(.systemGray6))
                .frame(width: 50, height: 56)

            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? Color.billixMoneyGreen : (isFilled ? Color.billixMoneyGreen.opacity(0.3) : Color.clear),
                    lineWidth: isActive ? 2 : 1
                )
                .frame(width: 50, height: 56)

            if digit.isEmpty && isActive {
                // Blinking cursor
                Rectangle()
                    .fill(Color.billixMoneyGreen)
                    .frame(width: 2, height: 24)
                    .opacity(isActive ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isActive)
            } else {
                Text(digit)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.billixDarkGreen)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFilled)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Provider Card

struct ProviderCard: View {
    let provider: BillProvider
    let isSelected: Bool
    var namespace: Namespace.ID
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Provider icon with solid color
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.billixMoneyGreen : Color(.systemGray5))
                        .frame(width: 48, height: 48)
                        .shadow(color: isSelected ? .billixMoneyGreen.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)

                    Image(systemName: "building.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSelected ? .white : .billixMediumGreen)
                }

                // Provider info - just name and category, clean and simple
                VStack(alignment: .leading, spacing: 4) {
                    Text(provider.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Text(provider.category.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(.billixMediumGreen)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.billixMoneyGreen : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.billixMoneyGreen)
                            .frame(width: 16, height: 16)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.billixMoneyGreen.opacity(0.08) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.billixMoneyGreen : Color(.systemGray5), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(isSelected ? 0.08 : 0.04), radius: isSelected ? 12 : 6, y: isSelected ? 6 : 3)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.98))
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Shimmer Loading Card

struct ShimmerCard: View {
    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 80, height: 10)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.5), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset)
        )
        .clipped()
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
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
                QuickAddStep2Provider(viewModel: viewModel, namespace: namespace)
            }
            .onAppear {
                viewModel.onAppear()
                viewModel.zipCode = "48104"
            }
        }
    }

    return PreviewWrapper()
}
