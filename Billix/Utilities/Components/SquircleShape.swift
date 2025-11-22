import SwiftUI

/// Custom squircle shape (rounded square with continuous curves like iOS app icons)
struct SquircleShape: Shape {
    var cornerRadius: CGFloat = 0.225 // Proportion of size (0.225 gives iOS-like squircle)

    func path(in rect: CGRect) -> Path {
        let size = min(rect.width, rect.height)
        let radius = size * cornerRadius

        var path = Path()

        // Top-left corner
        path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))

        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))

        // Top-right corner (continuous curve)
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control1: CGPoint(x: rect.maxX - radius * 0.45, y: rect.minY),
            control2: CGPoint(x: rect.maxX, y: rect.minY + radius * 0.45)
        )

        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))

        // Bottom-right corner (continuous curve)
        path.addCurve(
            to: CGPoint(x: rect.maxX - radius, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.maxY - radius * 0.45),
            control2: CGPoint(x: rect.maxX - radius * 0.45, y: rect.maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))

        // Bottom-left corner (continuous curve)
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - radius),
            control1: CGPoint(x: rect.minX + radius * 0.45, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.maxY - radius * 0.45)
        )

        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))

        // Top-left corner (continuous curve)
        path.addCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + radius * 0.45),
            control2: CGPoint(x: rect.minX + radius * 0.45, y: rect.minY)
        )

        return path
    }
}

/// Profile picture view with squircle shape
struct SquircleProfileImage: View {
    let size: CGFloat
    let imageName: String? = nil // For future user image
    let initials: String
    let gradientColors: [Color]

    init(size: CGFloat, initials: String, gradientColors: [Color] = [Color.billixLoginTeal, Color.billixMoneyGreen]) {
        self.size = size
        self.initials = initials
        self.gradientColors = gradientColors
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(SquircleShape())

            // Initials
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: gradientColors.first?.opacity(0.3) ?? .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 32) {
        SquircleProfileImage(size: 80, initials: "SR")
        SquircleProfileImage(size: 60, initials: "JD", gradientColors: [.purple, .pink])
        SquircleProfileImage(size: 120, initials: "MK", gradientColors: [.orange, .red])
    }
    .padding()
    .background(Color.billixLightGreen)
}
