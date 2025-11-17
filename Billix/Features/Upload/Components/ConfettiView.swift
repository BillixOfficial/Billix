import SwiftUI

struct ConfettiView: View {
    @Binding var counter: Int
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiShape()
                        .fill(piece.color)
                        .frame(width: 10, height: 10)
                        .offset(x: piece.x, y: piece.y)
                        .rotationEffect(.degrees(piece.rotation))
                        .opacity(piece.opacity)
                }
            }
            .onChange(of: counter) { _, _ in
                createConfetti(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    func createConfetti(in size: CGSize) {
        let colors: [Color] = [.billixGoldenAmber, .billixDarkTeal, .billixMoneyGreen, .billixPurple, .billixCopper]

        for _ in 0..<50 {
            let piece = ConfettiPiece(
                id: UUID(),
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
            confettiPieces.append(piece)

            // Animate falling
            withAnimation(.easeOut(duration: 2.0)) {
                if let index = confettiPieces.firstIndex(where: { $0.id == piece.id }) {
                    confettiPieces[index].y = size.height + 20
                    confettiPieces[index].rotation += 720
                    confettiPieces[index].opacity = 0
                }
            }

            // Clean up
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                confettiPieces.removeAll { $0.id == piece.id }
            }
        }

        // Haptic feedback
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            impact.impactOccurred()
        }
        #endif
    }
}

struct ConfettiPiece: Identifiable {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var rotation: Double
    var opacity: Double
}

struct ConfettiShape: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addRect(rect)
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var counter = 0

        var body: some View {
            ZStack {
                Color.billixCreamBeige.ignoresSafeArea()

                VStack {
                    Button("Trigger Confetti") {
                        counter += 1
                    }
                    .font(.headline)
                    .padding()
                    .background(Color.billixDarkTeal)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                ConfettiView(counter: $counter)
            }
        }
    }

    return PreviewWrapper()
}
