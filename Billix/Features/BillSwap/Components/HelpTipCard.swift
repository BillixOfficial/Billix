//
//  HelpTipCard.swift
//  Billix
//
//  Collapsible help tip card for contextual guidance
//

import SwiftUI

struct HelpTipCard: View {
    let icon: String
    let title: String
    let message: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.billixMoneyGreen)

                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.billixDarkTeal)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color.billixMoneyGreen.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct HelpTipCard_Help_Tip_Card_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
        HelpTipCard(
        icon: "checkmark.shield",
        title: "Why do we scan your bill?",
        message: "OCR verification confirms your bill is authentic, protecting both you and your connection partner from fraud."
        )
        
        HelpTipCard(
        icon: "star.fill",
        title: "About tier limits",
        message: "Tier limits protect new users. As you complete successful connections, your limit increases automatically."
        )
        
        HelpTipCard(
        icon: "lock.shield",
        title: "Guest pay links",
        message: "Guest pay links let your partner pay your bill without accessing your account credentials. This keeps both parties secure."
        )
        }
        .padding()
    }
}
