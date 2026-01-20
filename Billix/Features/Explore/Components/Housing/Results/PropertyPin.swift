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
    let isMain: Bool  // true = blue pin (searched property), false = comparable
    let isActive: Bool  // true = green (active listing), false = gray (inactive)
    let index: Int?  // 1, 2, 3... for numbered pins (like RentCast)

    @State private var pulseScale: CGFloat = 1.0

    init(isSelected: Bool, isMain: Bool, isActive: Bool = true, index: Int? = nil) {
        self.isSelected = isSelected
        self.isMain = isMain
        self.isActive = isActive
        self.index = index
    }

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

            // Show number if index provided, location marker for searched property
            if let index = index {
                Text("\(index)")
                    .font(.system(size: isSelected ? 14 : 11, weight: .bold))
                    .foregroundColor(.white)
            } else if isMain {
                // Searched property - show location marker
                Image(systemName: "mappin")
                    .font(.system(size: isSelected ? 14 : 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var pinColor: Color {
        if isSelected { return .blue }
        if isMain { return .blue }
        // Numbered pins use teal, otherwise active=green, inactive=coral
        if index != nil { return .billixDarkTeal }
        return isActive ? .billixMoneyGreen : Color(red: 0.85, green: 0.45, blue: 0.45)
    }
}

#Preview("Property Pins") {
    VStack(spacing: 24) {
        HStack(spacing: 40) {
            VStack(spacing: 8) {
                PropertyPin(isSelected: false, isMain: true, isActive: true)
                Text("Main")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 8) {
                PropertyPin(isSelected: true, isMain: false, isActive: true)
                Text("Selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }

        HStack(spacing: 40) {
            VStack(spacing: 8) {
                PropertyPin(isSelected: false, isMain: false, isActive: true)
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.billixMoneyGreen)
            }

            VStack(spacing: 8) {
                PropertyPin(isSelected: false, isMain: false, isActive: false)
                Text("Inactive")
                    .font(.caption)
                    .foregroundColor(Color(red: 0.85, green: 0.45, blue: 0.45))
            }
        }
    }
    .padding()
    .background(Color.billixCreamBeige)
}
