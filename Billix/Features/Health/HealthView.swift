import SwiftUI

struct HealthView: View {
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
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.billixCopper)

                    Text("Health")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Track your wellness")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HealthView_Previews: PreviewProvider {
    static var previews: some View {
        HealthView()
    }
}
