import SwiftUI

struct UploadView: View {
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
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.billixGoldenAmber)

                    Text("Upload")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Add new content")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .navigationTitle("Upload")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    UploadView()
}
