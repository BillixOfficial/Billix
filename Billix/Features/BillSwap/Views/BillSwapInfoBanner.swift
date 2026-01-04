//
//  BillSwapInfoBanner.swift
//  Billix
//
//  Collapsible info banner explaining how Bill Swap works
//

import SwiftUI

struct BillSwapInfoBanner: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(Color.billixMoneyGreen)

                    Text("How Bill Swap Works")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "2D3B35"))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "666666"))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            // Expandable content
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                        .padding(.horizontal, 16)

                    // Introduction
                    Text("Exchange bill payments with trusted users in your community.")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "666666"))
                        .padding(.horizontal, 16)

                    // Steps
                    VStack(alignment: .leading, spacing: 12) {
                        InfoStep(
                            number: 1,
                            title: "Add Your Bill",
                            description: "Upload a photo and details of your bill that needs to be paid."
                        )

                        InfoStep(
                            number: 2,
                            title: "Find a Match",
                            description: "Browse available bills or wait for someone to match with yours."
                        )

                        InfoStep(
                            number: 3,
                            title: "Pay Each Other's Bills",
                            description: "You pay their bill, they pay yours. Submit proof of payment."
                        )

                        InfoStep(
                            number: 4,
                            title: "Earn Trust",
                            description: "Complete swaps to unlock higher bill limits and more features."
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Info Step

private struct InfoStep: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.billixMoneyGreen)
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "2D3B35"))

                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(hex: "666666"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    ZStack {
        Color(hex: "F7F9F8")
            .ignoresSafeArea()

        VStack {
            BillSwapInfoBanner()
                .padding(.horizontal, 20)

            Spacer()
        }
        .padding(.top, 20)
    }
}
