//
//  SearchSettingsPanel.swift
//  Billix
//
//  Created by Claude Code on 1/5/26.
//  Search radius and lookback period sliders
//

import SwiftUI

struct SearchSettingsPanel: View {
    @Binding var searchRadius: Double  // miles
    @Binding var lookbackDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("Comparable settings:")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                // PRO badge (visual only, not functional)
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10))
                    Text("PRO")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.blue)
                )
            }

            VStack(spacing: 16) {
                // Search Radius Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Search radius:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(searchRadius, specifier: "%.1f") mi")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.billixDarkTeal)
                            .monospacedDigit()
                    }

                    Slider(value: $searchRadius, in: 0.5...5.0, step: 0.5)
                        .tint(.billixDarkTeal)
                        .accessibilityLabel("Search radius")
                        .accessibilityValue("\(searchRadius, specifier: "%.1f") miles")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                )

                // Lookback Period Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Look back period:")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()

                        Text("\(lookbackDays) days")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.billixDarkTeal)
                            .monospacedDigit()
                    }

                    Slider(value: Binding(
                        get: { Double(lookbackDays) },
                        set: { lookbackDays = Int($0) }
                    ), in: 7...90, step: 7)
                        .tint(.billixDarkTeal)
                        .accessibilityLabel("Look back period")
                        .accessibilityValue("\(lookbackDays) days")
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.04), radius: 4)
                )
            }
        }
    }
}

#Preview("Search Settings Panel") {
    SearchSettingsPanel(
        searchRadius: .constant(1.0),
        lookbackDays: .constant(30)
    )
    .padding()
    .background(Color.billixCreamBeige)
}
