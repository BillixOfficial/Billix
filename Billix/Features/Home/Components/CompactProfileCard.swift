import SwiftUI

struct CompactProfileCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image - Rounded square like screenshot
            Image(systemName: "person.crop.square.fill")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 60, height: 60)
                .foregroundColor(.billixLoginTeal.opacity(0.3))
                .background(Color.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )

            // Info Stack
            VStack(alignment: .leading, spacing: 4) {
                // Name + Verified Badge
                HStack(spacing: 6) {
                    Text("Ronald Richards")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.billixDarkGreen)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }

                // Join Date
                Text("May 20, 2024")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                // Quick Stats
                HStack(spacing: 12) {
                    // Star Rating
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.billixStarGold)
                        Text("4.5")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.billixDarkGreen)
                    }

                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))

                    Text("16 bills")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixDarkGreen)

                    Text("•")
                        .foregroundColor(.gray.opacity(0.5))

                    Text("$245 saved")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.billixMoneyGreen)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    CompactProfileCard()
        .padding()
        .background(Color.billixLightGreen)
}
