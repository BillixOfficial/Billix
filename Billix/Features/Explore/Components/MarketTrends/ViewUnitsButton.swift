//
//  ViewUnitsButton.swift
//  Billix
//
//  Created by Claude Code on 1/12/26.
//  Prominent CTA button to navigate to Housing tab
//

import SwiftUI

struct ViewUnitsButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("View Available Units")
                    .font(.system(size: 17, weight: .semibold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color.billixDarkTeal,
                        Color.billixDarkTeal.opacity(0.8)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.billixDarkTeal.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

struct ViewUnitsButton_View_Units_Button_Previews: PreviewProvider {
    static var previews: some View {
        ViewUnitsButton {
        print("Navigate to Housing tab")
        }
        .padding(20)
        .background(Color(hex: "F8F9FA"))
    }
}
