//
//  TimeRangeSelector.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Button group for selecting time range (6M, 1Y, All Time)
//

import SwiftUI

struct TimeRangeSelector: View {
    @Binding var selectedRange: TimeRange

    var body: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: selectedRange == range ? .bold : .medium))
                        .foregroundColor(selectedRange == range ? .white : .billixDarkTeal)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedRange == range ? Color.billixDarkTeal : Color.gray.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

struct TimeRangeSelector_Time_Range_Selector_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
        TimeRangeSelector(selectedRange: .constant(.sixMonths))
        TimeRangeSelector(selectedRange: .constant(.oneYear))
        TimeRangeSelector(selectedRange: .constant(.allTime))
        }
        .padding()
        .background(Color.billixCreamBeige)
    }
}
