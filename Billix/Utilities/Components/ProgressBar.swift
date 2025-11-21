import SwiftUI

struct ProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let height: CGFloat
    let backgroundColor: Color
    let foregroundColor: Color
    let cornerRadius: CGFloat
    let animated: Bool

    @State private var animatedProgress: Double = 0

    init(
        progress: Double,
        height: CGFloat = 8,
        backgroundColor: Color = Color.gray.opacity(0.2),
        foregroundColor: Color = .blue,
        cornerRadius: CGFloat = 4,
        animated: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.cornerRadius = cornerRadius
        self.animated = animated
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(foregroundColor)
                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress), height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = progress
                }
            }
        }
    }
}
