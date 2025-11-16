import SwiftUI

struct ExploreView: View {
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.billixCreamBeige,
                        Color.billixGoldenAmber.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.billixMoneyGreen)

                    Text("Explore")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Discover new features")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ExploreView()
}
