import SwiftUI

struct CountUp: View {
    let end: Double
    let duration: Double
    let prefix: String
    let suffix: String
    let decimals: Int

    @State private var currentValue: Double = 0

    init(
        end: Double,
        duration: Double = 1.0,
        prefix: String = "",
        suffix: String = "",
        decimals: Int = 0
    ) {
        self.end = end
        self.duration = duration
        self.prefix = prefix
        self.suffix = suffix
        self.decimals = decimals
    }

    var body: some View {
        Text("\(prefix)\(formattedValue)\(suffix)")
            .onAppear {
                withAnimation(.easeOut(duration: duration)) {
                    currentValue = end
                }
            }
    }

    private var formattedValue: String {
        if decimals == 0 {
            return String(format: "%.0f", currentValue)
        } else {
            return String(format: "%.\(decimals)f", currentValue)
        }
    }
}
