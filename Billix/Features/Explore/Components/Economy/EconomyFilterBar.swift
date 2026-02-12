//
//  EconomyFilterBar.swift
//  Billix
//
//  Created by Claude Code on 1/19/26.
//  Category filter pills for Economy feed - matches design spec
//

import SwiftUI

struct EconomyFilterBar: View {
    @Binding var selectedCategory: EconomyCategory
    let categories: [EconomyCategory]

    init(selected: Binding<EconomyCategory>, categories: [EconomyCategory] = EconomyCategory.allCases) {
        self._selectedCategory = selected
        self.categories = categories
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    EconomyCategoryPill(
                        label: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Category Pill Component

struct EconomyCategoryPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    // Design spec colors
    private let accentBlue = Color(hex: "#3B6CFF")
    private let inactiveBackground = Color(hex: "#F3F4F6")
    private let inactiveText = Color(hex: "#1A1A1A")

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? .white : inactiveText)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? accentBlue : inactiveBackground)
                )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.95))
        .accessibilityLabel("Filter by \(label)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct EconomyFilterBar_Economy_Filter_Bar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
        Color.white
        .ignoresSafeArea()
        
        VStack {
        EconomyFilterBar(
        selected: .constant(.all)
        )
        Spacer()
        }
        .padding(.top, 20)
        }
    }
}
