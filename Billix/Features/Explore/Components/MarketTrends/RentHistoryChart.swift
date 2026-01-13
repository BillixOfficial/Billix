//
//  RentHistoryChart.swift
//  Billix
//
//  Created by Claude Code on 1/6/26.
//  Multi-line historical rent chart using Swift Charts
//

import SwiftUI
import Charts
import UIKit

enum ChartMode {
    case averageOnly  // Show only average with gradient
    case allTypes     // Show all 7 bedroom types
}

struct RentHistoryChart: View {
    let historyData: [RentHistoryPoint]
    let timeRange: TimeRange
    let chartMode: ChartMode
    let selectedBedroomTypes: Set<BedroomType>
    @Binding var selectedDataPoint: RentHistoryPoint?
    @Binding var isScrubbing: Bool

    @State private var rawSelectedDate: Date?
    @State private var touchedRent: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
            Text("HISTORICAL PERFORMANCE")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .tracking(0.5)
                .padding(.top, 8)
                .frame(maxWidth: .infinity, alignment: .center)

            // Chart with scrubbing label overlay
            ZStack(alignment: .topLeading) {
                // Chart
                Chart {
                    chartMarks
                }
                .chartXAxis {
                switch timeRange {
                case .sixMonths:
                    // Show abbreviated months
                    AxisMarks(values: .stride(by: .month)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))

                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }

                case .oneYear:
                    // Show every 2 months for better spacing
                    AxisMarks(values: .stride(by: .month, count: 2)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))

                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(.system(size: 10))
                            .foregroundStyle(Color.secondary)
                    }

                case .allTime:
                    // Show years with proper stride
                    AxisMarks(values: .stride(by: .year)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gray.opacity(0.2))

                        AxisValueLabel(format: .dateTime.year())
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .chartPlotStyle { plotArea in
                plotArea
                    .padding(.horizontal, 8)
                    .padding(.bottom, 20)
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
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
            .chartOverlay { chartProxy in
                GeometryReader { geometry in
                    let plotAreaFrame = geometry[chartProxy.plotAreaFrame]

                    ZStack {
                        // Gesture detection layer (always present, invisible)
                        Color.clear
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let xPosition = value.location.x
                                        let yPosition = value.location.y

                                        if let date: Date = chartProxy.value(atX: xPosition) {
                                            rawSelectedDate = date

                                            // Calculate rent from Y position using plot area
                                            let plotHeight = plotAreaFrame.height
                                            let yRelativeToPlot = yPosition - plotAreaFrame.minY
                                            let normalizedY = max(0, min(1, yRelativeToPlot / plotHeight))

                                            let rentRange = yAxisRange.upperBound - yAxisRange.lowerBound
                                            let calculatedRent = yAxisRange.upperBound - (normalizedY * rentRange)

                                            touchedRent = calculatedRent
                                        }
                                    }
                                    .onEnded { _ in
                                        rawSelectedDate = nil
                                        touchedRent = nil
                                    }
                            )

                        // Crosshair visualization (only when scrubbing)
                        if let selectedPoint = selectedDataPoint, isScrubbing {
                            if let xPosition = chartProxy.position(forX: selectedPoint.date),
                               let yPosition = chartProxy.position(forY: selectedPoint.rent) {

                                ZStack(alignment: .topLeading) {
                                    // Vertical crosshair line
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: 1.5)
                                        .position(x: xPosition, y: geometry.size.height / 2)

                                    // Dot at data point
                                    Circle()
                                        .fill(Color.billixDarkTeal)
                                        .frame(width: 12, height: 12)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 2.5)
                                        )
                                        .position(x: xPosition, y: yPosition)

                                    // Scrubbing label
                                    scrubbingLabel(for: selectedPoint)
                                        .offset(x: calculateLabelXOffset(xPosition: xPosition, geometry: geometry), y: max(yPosition - 60, 10))
                                }
                                .transition(.opacity)
                                .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .onChange(of: rawSelectedDate) { oldValue, newValue in
                if let date = newValue {
                    // Find closest data point to selected date and rent value
                    let point = findClosestDataPoint(to: date, rent: touchedRent)
                    selectedDataPoint = point
                    isScrubbing = true

                    // Haptic feedback
                    if oldValue != nil && point?.id != selectedDataPoint?.id {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else {
                    // User lifted finger
                    withAnimation(.easeOut(duration: 0.2)) {
                        selectedDataPoint = nil
                        isScrubbing = false
                        touchedRent = nil
                    }
                }
            }
            .frame(height: 280)
            }

            // Legend (show in allTypes mode)
            if chartMode == .allTypes {
                let legendTypes = selectedBedroomTypes.isEmpty
                    ? Array(BedroomType.allCases.filter { $0 != .average })
                    : Array(selectedBedroomTypes)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(legendTypes, id: \.self) { type in
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
                    .padding(.horizontal, 8)
                }
                .padding(.top, 4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Scrubbing Label Overlay

    private func scrubbingLabel(for point: RentHistoryPoint) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        let dateString = formatter.string(from: point.date)

        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.currencySymbol = "$"
        priceFormatter.maximumFractionDigits = 2
        priceFormatter.minimumFractionDigits = 2
        let priceString = priceFormatter.string(from: NSNumber(value: point.rent)) ?? "$0.00"

        return VStack(alignment: .leading, spacing: 2) {
            Text(dateString)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)

            Text(priceString)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.85))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }

    private func calculateLabelXOffset(xPosition: CGFloat, geometry: GeometryProxy) -> CGFloat {
        let labelWidth: CGFloat = 100 // Approximate label width

        // Keep label on screen
        if xPosition < labelWidth / 2 {
            return 10 // Left edge
        } else if xPosition > geometry.size.width - labelWidth / 2 {
            return geometry.size.width - labelWidth - 10 // Right edge
        } else {
            return xPosition - labelWidth / 2 // Centered on touch point
        }
    }

    @ChartContentBuilder
    private var chartMarks: some ChartContent {
        if chartMode == .averageOnly {
            // Show only average line with gradient fill
            let averageData = historyData.filter { $0.bedroomType == .average }

            ForEach(averageData) { point in
                // LineMark for the line
                LineMark(
                    x: .value("Month", point.date),
                    y: .value("Rent", point.rent)
                )
                .foregroundStyle(Color.billixDarkTeal)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 3))

                // AreaMark for gradient fill
                AreaMark(
                    x: .value("Month", point.date),
                    yStart: .value("Base", yAxisRange.lowerBound),
                    yEnd: .value("Rent", point.rent)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.billixDarkTeal.opacity(0.3),
                            Color.billixDarkTeal.opacity(0.05),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }
        } else {
            // Breakdown tab: Show selected bedroom types with gradient fills
            let typesToShow = selectedBedroomTypes.isEmpty
                ? Array(BedroomType.allCases.filter { $0 != .average })
                : Array(selectedBedroomTypes)

            ForEach(typesToShow, id: \.self) { bedroomType in
                let typeData = historyData.filter { $0.bedroomType == bedroomType }

                // AreaMark for gradient fill (render first, behind line)
                ForEach(typeData) { point in
                    AreaMark(
                        x: .value("Month", point.date),
                        yStart: .value("Base", yAxisRange.lowerBound),
                        yEnd: .value("Rent", point.rent),
                        series: .value("Type", bedroomType.rawValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                bedroomType.chartColor.opacity(0.2),
                                bedroomType.chartColor.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // LineMark for the line (render on top)
                ForEach(typeData) { point in
                    LineMark(
                        x: .value("Month", point.date),
                        y: .value("Rent", point.rent),
                        series: .value("Type", bedroomType.rawValue)
                    )
                    .foregroundStyle(bedroomType.chartColor)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
            }
        }
    }

    private var yAxisRange: ClosedRange<Double> {
        let allRents = historyData.map { $0.rent }
        let minRent = allRents.min() ?? 800
        let maxRent = allRents.max() ?? 2000

        // Add 10% padding
        let padding = (maxRent - minRent) * 0.1
        return (minRent - padding)...(maxRent + padding)
    }

    private func findClosestDataPoint(to date: Date, rent: Double?) -> RentHistoryPoint? {
        // Filter by chart mode
        let relevantData: [RentHistoryPoint]
        if chartMode == .averageOnly {
            relevantData = historyData.filter { $0.bedroomType == .average }
        } else {
            // In breakdown mode, only consider visible bedroom types
            let typesToShow = selectedBedroomTypes.isEmpty
                ? Array(BedroomType.allCases.filter { $0 != .average })
                : Array(selectedBedroomTypes)
            relevantData = historyData.filter { typesToShow.contains($0.bedroomType) }
        }

        guard !relevantData.isEmpty else { return nil }

        // STEP 1: Find the closest date (X-axis lock)
        let closestDate = relevantData.map { $0.date }
            .min(by: { abs($0.timeIntervalSince(date)) < abs($1.timeIntervalSince(date)) })

        guard let closestDate = closestDate else { return nil }

        // STEP 2: Get all points at that date (one per line)
        let pointsAtDate = relevantData.filter { point in
            // Allow small time difference for floating point comparison
            abs(point.date.timeIntervalSince(closestDate)) < 1.0
        }

        // STEP 3: Among those points, find the one with rent closest to touch Y
        if let rent = rent {
            return pointsAtDate.min(by: { abs($0.rent - rent) < abs($1.rent - rent) })
        } else {
            // No Y-value, just return first point at this date
            return pointsAtDate.first
        }
    }
}

// MARK: - Preview

#Preview("Rent History Chart - All Types") {
    struct PreviewWrapper: View {
        @State private var selectedDataPoint: RentHistoryPoint?
        @State private var isScrubbing: Bool = false
        let mockData = MarketTrendsMockData.generateHistoryData(
            location: "New York, NY",
            monthsBack: 12
        )

        var body: some View {
            RentHistoryChart(
                historyData: mockData,
                timeRange: .oneYear,
                chartMode: .allTypes,
                selectedBedroomTypes: [.studio, .oneBed],
                selectedDataPoint: $selectedDataPoint,
                isScrubbing: $isScrubbing
            )
            .padding()
            .background(Color.billixCreamBeige)
        }
    }

    return PreviewWrapper()
}

#Preview("Rent History Chart - Average Only") {
    struct PreviewWrapper: View {
        @State private var selectedDataPoint: RentHistoryPoint?
        @State private var isScrubbing: Bool = false
        let mockData = MarketTrendsMockData.generateHistoryData(
            location: "New York, NY",
            monthsBack: 12
        )

        var body: some View {
            RentHistoryChart(
                historyData: mockData,
                timeRange: .oneYear,
                chartMode: .averageOnly,
                selectedBedroomTypes: [],
                selectedDataPoint: $selectedDataPoint,
                isScrubbing: $isScrubbing
            )
            .padding()
            .background(Color.billixCreamBeige)
        }
    }

    return PreviewWrapper()
}
