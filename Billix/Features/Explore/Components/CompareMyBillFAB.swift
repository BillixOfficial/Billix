//
//  CompareMyBillFAB.swift
//  Billix
//
//  Created by Claude Code on 1/4/26.
//  Floating action button for "Compare Me" feature on Bills tab
//

import SwiftUI

/// Floating action button for uploading/comparing bills
struct CompareMyBillFAB: View {

    // MARK: - Properties

    @State private var isVisible = true
    @State private var isPressed = false

    // MARK: - Body

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Spacer()

                NavigationLink(destination: destinationView) {
                    HStack(spacing: 10) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Compare Me")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.billixGoldenAmber,
                                        Color.billixGoldenAmber.opacity(0.9)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(
                                color: Color.billixGoldenAmber.opacity(0.4),
                                radius: isPressed ? 8 : 12,
                                x: 0,
                                y: isPressed ? 3 : 6
                            )
                    )
                }
                .scaleEffect(isVisible ? (isPressed ? 0.95 : 1.0) : 0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in isPressed = true }
                        .onEnded { _ in isPressed = false }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 90) // Above tab bar
            }
        }
    }

    // MARK: - Destination

    @ViewBuilder
    private var destinationView: some View {
        // This would navigate to the upload flow in the real app
        // For now, just show a placeholder
        Text("Upload Flow")
            .font(.title)
            .navigationTitle("Compare Your Bill")
    }
}

// MARK: - Previews

#Preview("Compare FAB") {
    ZStack {
        // Simulated background content
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<10) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .frame(height: 200)
                }
            }
            .padding()
        }
        .background(Color.billixCreamBeige)

        // FAB overlay
        CompareMyBillFAB()
    }
}

#Preview("FAB in Context") {
    NavigationView {
        ZStack {
            Color.billixCreamBeige.ignoresSafeArea()

            CompareMyBillFAB()
        }
        .navigationBarHidden(true)
    }
}
