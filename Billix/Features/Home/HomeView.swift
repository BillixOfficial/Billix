import SwiftUI

struct HomeView: View {
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
                    Image(systemName: "house.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.billixPurple)

                    Text("Home")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Welcome to Billix")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HomeView()
}
