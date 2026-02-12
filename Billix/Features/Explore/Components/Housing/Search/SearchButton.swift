//
//  SearchButton.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Primary search button with loading state
//

import SwiftUI

struct SearchButton: View {
    let action: () -> Void
    let isEnabled: Bool
    let isLoading: Bool

    init(action: @escaping () -> Void, isEnabled: Bool = true, isLoading: Bool = false) {
        self.action = action
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                }

                Text(isLoading ? "Searching..." : "Search")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: [Color(hex: "00A8E8"), Color(hex: "0077B6")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: isEnabled ? Color(hex: "00A8E8").opacity(0.4) : .clear,
                radius: 12,
                x: 0,
                y: 6
            )
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(isLoading ? "Searching for properties" : "Search for properties")
    }
}

struct SearchButton_Search_Buttons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        SearchButton(action: {}, isEnabled: true, isLoading: false)
        SearchButton(action: {}, isEnabled: false, isLoading: false)
        SearchButton(action: {}, isEnabled: true, isLoading: true)
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
