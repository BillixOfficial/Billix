//
//  RentHistoryChart.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Multi-line historical rent chart using Swift Charts
//

import SwiftUI
import Charts

struct RentHistoryChart: View {
    let historyData: [RentHistoryPoint]
    let timeRange: TimeRange

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("HISTORICAL PERFORMANCE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)

            // Chart
            Chart {
                ForEach(BedroomType.allCases) { bedroomType in
                    let typeData = historyData.filter { $0.bedroomType == bedroomType }

                    ForEach(typeData) { point in
                        LineMark(
                            x: .value("Month", point.date),
                            y: .value("Rent", point.rent)
                        )
                        .foregroundStyle(bedroomType.chartColor)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                    }
                }
            }
            .frame(height: 250)
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))

                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(Color.gray.opacity(0.2))

                    AxisValueLabel {
                        if let rent = value.as(Double.self) {
                            Text("$\(Int(rent))")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisRange)

            // Legend
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(BedroomType.allCases) { type in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(type.chartColor)
                                .frame(width: 10, height: 10)

                            Text(type.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    private var yAxisRange: ClosedRange<Double> {
        let allRents = historyData.map { $0.rent }
        let minRent = allRents.min() ?? 800
        let maxRent = allRents.max() ?? 2000

        // Add 10% padding
        let padding = (maxRent - minRent) * 0.1
        return (minRent - padding)...(maxRent + padding)
    }
}

// MARK: - Preview

#Preview("Rent History Chart") {
    let mockData = MarketTrendsMockData.generateHistoryData(
        location: "New York, NY",
        monthsBack: 12
    )

    return RentHistoryChart(
        historyData: mockData,
        timeRange: .oneYear
    )
    .padding()
    .background(Color.billixCreamBeige)
}
