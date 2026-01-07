//
//  PropertyPin.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Interactive map pin with selection states
//

import SwiftUI

struct PropertyPin: View {
    let isSelected: Bool
    let isMain: Bool  // true = blue pin (searched property), false = green pin (comparable)

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Outer pulse ring for selected pin
            if isSelected {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                    .frame(width: 36, height: 36)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true)
                        ) {
                            pulseScale = 1.2
                        }
                    }
            }

            // Main pin circle
            Circle()
                .fill(pinColor)
                .frame(
                    width: isSelected ? 30 : 24,
                    height: isSelected ? 30 : 24
                )
                .overlay(
                    Circle()
                        .strokeBorder(isSelected ? .white : .clear, lineWidth: 2)
                )

            // House icon
            Image(systemName: "house.fill")
                .font(.system(size: isSelected ? 14 : 12))
                .foregroundColor(.white)
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var pinColor: Color {
        if isSelected { return .blue }
        if isMain { return .blue }
        return .billixMoneyGreen
    }
}

#Preview("Property Pins") {
    HStack(spacing: 40) {
        VStack(spacing: 8) {
            PropertyPin(isSelected: false, isMain: true)
            Text("Main")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        VStack(spacing: 8) {
            PropertyPin(isSelected: true, isMain: false)
            Text("Selected")
                .font(.caption)
                .foregroundColor(.secondary)
        }

        VStack(spacing: 8) {
            PropertyPin(isSelected: false, isMain: false)
            Text("Comparable")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    .padding()
    .background(Color.billixCreamBeige)
}
