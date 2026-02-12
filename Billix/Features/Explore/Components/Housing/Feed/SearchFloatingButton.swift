//
//  SearchFloatingButton.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Floating action button to open detailed search sheet
//

import SwiftUI

struct SearchFloatingButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))

                Text("Search")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "00A8E8"), Color(hex: "0077B6")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "00A8E8").opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .accessibilityLabel("Open detailed property search")
    }
}

struct SearchFloatingButton_Search_Floating_Button_Previews: PreviewProvider {
    static var previews: some View {
        SearchFloatingButton(action: {})
        .padding()
        .background(Color.billixCreamBeige)
    }
}
