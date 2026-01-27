//
//  BillReactionsBar.swift
//  Billix
//
//  Created by Claude Code on 1/26/26.
//  Reaction buttons for bill listings
//

import SwiftUI

struct BillReactionsBar: View {
    let reactions: [BillReactionType: Int]
    let commentCount: Int
    let onReactionTapped: (BillReactionType) -> Void
    let onCommentTapped: () -> Void

    @State private var selectedReaction: BillReactionType?

    private let metadataGrey = Color(hex: "#6B7280")

    var body: some View {
        HStack(spacing: 0) {
            // Reaction buttons
            ForEach(BillReactionType.allCases, id: \.self) { reaction in
                reactionButton(reaction)
            }

            Spacer()

            // Comment button
            Button {
                onCommentTapped()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 14))
                    Text("\(commentCount)")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(metadataGrey)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    private func reactionButton(_ reaction: BillReactionType) -> some View {
        let count = reactions[reaction] ?? 0
        let isSelected = selectedReaction == reaction

        return Button {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()

            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedReaction == reaction {
                    selectedReaction = nil
                } else {
                    selectedReaction = reaction
                }
            }
            onReactionTapped(reaction)
        } label: {
            HStack(spacing: 3) {
                Text(reaction.emoji)
                    .font(.system(size: 14))
                if count > 0 || isSelected {
                    Text("\(isSelected ? count + 1 : count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isSelected ? Color.billixDarkTeal : metadataGrey)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                Color.billixDarkTeal.opacity(0.1) :
                Color.clear
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("Bill Reactions Bar") {
    VStack(spacing: 20) {
        BillReactionsBar(
            reactions: [.looksLow: 12, .high: 3, .howDidYou: 5, .jumped: 2],
            commentCount: 8,
            onReactionTapped: { _ in },
            onCommentTapped: { }
        )
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
    .padding()
    .background(Color(hex: "#F5F5F7"))
}
