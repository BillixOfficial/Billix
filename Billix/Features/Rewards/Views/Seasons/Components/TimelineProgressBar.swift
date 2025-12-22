import SwiftUI

struct TimelineProgressBar: View {
    let progress: Double  // 0.0 to 1.0

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(height: 2)

                // Progress fill
                Rectangle()
                    .fill(Color(hex: "#F97316"))  // Orange
                    .frame(width: geometry.size.width * max(0, min(1, progress)), height: 2)
            }
        }
        .frame(height: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        VStack(alignment: .leading) {
            Text("0% Progress")
                .font(.caption)
            TimelineProgressBar(progress: 0.0)
                .frame(height: 2)
        }

        VStack(alignment: .leading) {
            Text("50% Progress")
                .font(.caption)
            TimelineProgressBar(progress: 0.5)
                .frame(height: 2)
        }

        VStack(alignment: .leading) {
            Text("80% Progress")
                .font(.caption)
            TimelineProgressBar(progress: 0.8)
                .frame(height: 2)
        }

        VStack(alignment: .leading) {
            Text("100% Progress")
                .font(.caption)
            TimelineProgressBar(progress: 1.0)
                .frame(height: 2)
        }
    }
    .padding()
}
