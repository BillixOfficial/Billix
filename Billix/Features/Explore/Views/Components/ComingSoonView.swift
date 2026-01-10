//
//  ComingSoonView.swift
//  Billix
//
//  Created by Claude Code on 1/10/26.
//  Placeholder view for features under development
//

import SwiftUI

struct ComingSoonView: View {
    let title: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.billixPurple.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 60))
                    .foregroundColor(.billixPurple)
            }

            // Title
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.black)

            // Coming Soon Message
            Text("Coming Soon")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.billixPurple)

            // Description
            Text("This feature is currently under development.\nCheck back soon for updates!")
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Coming Soon") {
    NavigationStack {
        ComingSoonView(title: "Economy by AI")
    }
}
