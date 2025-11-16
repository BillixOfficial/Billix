import SwiftUI

struct ProfileView: View {
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
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.billixDarkTeal)

                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.billixNavyBlue)

                    Text("Manage your account")
                        .font(.body)
                        .foregroundColor(.billixDarkTeal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ProfileView()
}
