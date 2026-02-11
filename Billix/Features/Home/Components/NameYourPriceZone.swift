//
//  NameYourPriceZone.swift
//  Billix
//
//  "Name Your Price" - Tell us what you want to pay, we'll get you there
//

import SwiftUI

struct NameYourPriceZone: View {
    let userState: String

    @ObservedObject private var priceTargetService = PriceTargetService.shared
    @State private var selectedBillType: PriceBillType?
    @State private var editingTarget: PriceTarget?
    @State private var viewingOptionsFor: PriceTarget?
    @State private var showAllBillTypes = false

    private var hasAnyTargets: Bool {
        !priceTargetService.priceTargets.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#5B8A6B"))

                Text("NAME YOUR PRICE")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .tracking(0.5)

                Spacer()

                if hasAnyTargets {
                    Button {
                        haptic()
                        showAllBillTypes = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10, weight: .bold))
                            Text("Add")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(hex: "#5B8A6B"))
                    }
                }
            }
            .padding(.horizontal, 20)

            if hasAnyTargets {
                // Show active price targets
                VStack(spacing: 12) {
                    ForEach(priceTargetService.priceTargets) { target in
                        let regionalAvg = priceTargetService.getRegionalAverage(for: target.billType, state: userState)
                        let options = priceTargetService.getOptions(for: target.billType, targetAmount: target.targetAmount, state: userState)

                        PriceTargetCard(
                            target: target,
                            regionalAverage: regionalAvg,
                            options: options,
                            onEdit: {
                                editingTarget = target
                            },
                            onViewOptions: {
                                viewingOptionsFor = target
                            },
                            onDelete: {
                                priceTargetService.removeTarget(billType: target.billType)
                            }
                        )
                    }

                    // Quick add buttons for common bill types not yet added
                    let remainingTypes = PriceBillType.allCases.filter { billType in
                        !priceTargetService.hasTarget(for: billType)
                    }

                    if !remainingTypes.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(remainingTypes.prefix(6)) { billType in
                                    AddPriceBillTypeButton(billType: billType) {
                                        selectedBillType = billType
                                    }
                                }
                                if remainingTypes.count > 6 {
                                    Button {
                                        haptic()
                                        showAllBillTypes = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text("+\(remainingTypes.count - 6) more")
                                                .font(.system(size: 13, weight: .medium))
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 10, weight: .semibold))
                                        }
                                        .foregroundColor(Color(hex: "#5B8A6B"))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: "#5B8A6B").opacity(0.1))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            } else {
                // Empty state - show bill types by category
                EmptyPriceState(
                    onSelectBillType: { billType in
                        selectedBillType = billType
                    }
                )
            }
        }
        .sheet(item: $selectedBillType) { billType in
            SetPriceSheet(
                billType: billType,
                regionalAverage: priceTargetService.getRegionalAverage(for: billType, state: userState),
                existingTarget: nil,
                onSave: { amount, provider, currentAmount, contactPref in
                    priceTargetService.setTarget(
                        billType: billType,
                        targetAmount: amount,
                        currentProvider: provider,
                        currentAmount: currentAmount,
                        contactPreference: contactPref
                    )
                }
            )
            .presentationDetents([.large])
        }
        .sheet(item: $editingTarget) { target in
            SetPriceSheet(
                billType: target.billType,
                regionalAverage: priceTargetService.getRegionalAverage(for: target.billType, state: userState),
                existingTarget: target,
                onSave: { amount, provider, currentAmount, contactPref in
                    priceTargetService.setTarget(
                        billType: target.billType,
                        targetAmount: amount,
                        currentProvider: provider,
                        currentAmount: currentAmount,
                        contactPreference: contactPref
                    )
                }
            )
            .presentationDetents([.large])
        }
        .sheet(item: $viewingOptionsFor) { target in
            let regionalAvg = priceTargetService.getRegionalAverage(for: target.billType, state: userState)
            let options = priceTargetService.getOptions(for: target.billType, targetAmount: target.targetAmount, state: userState)

            PriceOptionsSheet(
                billType: target.billType,
                targetAmount: target.targetAmount,
                regionalAverage: regionalAvg,
                options: options
            )
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showAllBillTypes) {
            AllBillTypesSheet(
                userState: userState,
                priceTargetService: priceTargetService,
                onSelect: { billType in
                    showAllBillTypes = false
                    Task { @MainActor in
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        selectedBillType = billType
                    }
                }
            )
            .presentationDetents([.large])
        }
    }
}

// MARK: - Empty State

private struct EmptyPriceState: View {
    let onSelectBillType: (PriceBillType) -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Tagline
            VStack(spacing: 6) {
                Text("Tell us what you want to pay.")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Text("We'll get you there.")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }
            .padding(.top, 8)

            // Popular bill types (first row)
            VStack(alignment: .leading, spacing: 12) {
                Text("Popular")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .padding(.leading, 4)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach([PriceBillType.electric, .internet, .gas, .phone]) { billType in
                        PriceBillTypeButton(billType: billType) {
                            onSelectBillType(billType)
                        }
                    }
                }
            }

            // More bill types
            VStack(alignment: .leading, spacing: 12) {
                Text("More")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(hex: "#8B9A94"))
                    .padding(.leading, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach([PriceBillType.water, .trash, .autoInsurance, .homeInsurance, .streaming, .cable, .rent]) { billType in
                            CompactBillTypeButton(billType: billType) {
                                onSelectBillType(billType)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
    }
}

// MARK: - All Bill Types Sheet

private struct AllBillTypesSheet: View {
    let userState: String
    let priceTargetService: PriceTargetService
    let onSelect: (PriceBillType) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(PriceBillCategory.allCases, id: \.self) { category in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(category.rawValue)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(hex: "#2D3B35"))

                            VStack(spacing: 8) {
                                ForEach(category.billTypes) { billType in
                                    let hasTarget = priceTargetService.hasTarget(for: billType)
                                    let avg = priceTargetService.getRegionalAverage(for: billType, state: userState)

                                    Button {
                                        haptic()
                                        if !hasTarget {
                                            onSelect(billType)
                                        }
                                    } label: {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(billType.color.opacity(0.12))
                                                    .frame(width: 44, height: 44)

                                                Image(systemName: billType.icon)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(billType.color)
                                            }

                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(billType.displayName)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(Color(hex: "#2D3B35"))

                                                Text("Avg: $\(Int(avg))/mo")
                                                    .font(.system(size: 13))
                                                    .foregroundColor(Color(hex: "#8B9A94"))
                                            }

                                            Spacer()

                                            if hasTarget {
                                                Text("Added")
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(Color(hex: "#5B8A6B"))
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 6)
                                                    .background(Color(hex: "#5B8A6B").opacity(0.1))
                                                    .cornerRadius(6)
                                            } else {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 22))
                                                    .foregroundColor(Color(hex: "#5B8A6B"))
                                            }
                                        }
                                        .padding(12)
                                        .background(Color.white)
                                        .cornerRadius(12)
                                        .opacity(hasTarget ? 0.6 : 1)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(hasTarget)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "#F7F9F8"))
            .navigationTitle("All Bill Types")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5B8A6B"))
                }
            }
        }
    }
}

// MARK: - Bill Type Button (for empty state grid)

private struct PriceBillTypeButton: View {
    let billType: PriceBillType
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            haptic()
            onTap()
        }) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(billType.color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: billType.icon)
                        .font(.system(size: 20))
                        .foregroundColor(billType.color)
                }

                Text(billType.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#2D3B35"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Compact Bill Type Button (for horizontal scroll)

private struct CompactBillTypeButton: View {
    let billType: PriceBillType
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            haptic()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: billType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(billType.color)

                Text(billType.displayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "#2D3B35"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(billType.color.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Add Bill Type Button (compact, for adding more)

private struct AddPriceBillTypeButton: View {
    let billType: PriceBillType
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            haptic()
            onTap()
        }) {
            HStack(spacing: 8) {
                Image(systemName: billType.icon)
                    .font(.system(size: 14))
                    .foregroundColor(billType.color)

                Text(billType.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(hex: "#2D3B35"))

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#5B8A6B"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            NameYourPriceZone(userState: "NJ")
        }
        .padding(.top, 20)
    }
    .background(Color(hex: "#F7F9F8"))
}
