import SwiftUI

struct Sparkline: View {
    let data: [Double]
    let lineColor: Color
    let lineWidth: CGFloat
    let showArea: Bool
    let areaOpacity: Double

    init(
        data: [Double],
        lineColor: Color = .blue,
        lineWidth: CGFloat = 2,
        showArea: Bool = false,
        areaOpacity: Double = 0.2
    ) {
        self.data = data
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showArea = showArea
        self.areaOpacity = areaOpacity
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if showArea {
                    Path { path in
                        guard let firstPoint = normalizedPoint(at: 0, in: geometry.size) else { return }

                        path.move(to: CGPoint(x: firstPoint.x, y: geometry.size.height))
                        path.addLine(to: firstPoint)

                        for index in 1..<data.count {
                            if let point = normalizedPoint(at: index, in: geometry.size) {
                                path.addLine(to: point)
                            }
                        }

                        path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [lineColor.opacity(areaOpacity), lineColor.opacity(0)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }

                Path { path in
                    guard let firstPoint = normalizedPoint(at: 0, in: geometry.size) else { return }
                    path.move(to: firstPoint)

                    for index in 1..<data.count {
                        if let point = normalizedPoint(at: index, in: geometry.size) {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(lineColor, lineWidth: lineWidth)
            }
        }
    }

    private func normalizedPoint(at index: Int, in size: CGSize) -> CGPoint? {
        guard !data.isEmpty, index < data.count else { return nil }

        let minValue = data.min() ?? 0
        let maxValue = data.max() ?? 1
        let range = maxValue - minValue

        guard range > 0 else {
            return CGPoint(
                x: CGFloat(index) / CGFloat(max(data.count - 1, 1)) * size.width,
                y: size.height / 2
            )
        }

        let x = CGFloat(index) / CGFloat(max(data.count - 1, 1)) * size.width
        let normalizedY = (data[index] - minValue) / range
        let y = size.height - (normalizedY * size.height)

        return CGPoint(x: x, y: y)
    }
}
