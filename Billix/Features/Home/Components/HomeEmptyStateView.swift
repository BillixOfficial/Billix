import SwiftUI

struct HomeEmptyStateView: View {
    let onUploadTap: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 180, height: 180)

                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 70))
                    .foregroundColor(.blue)
            }
            .padding(.top, 40)

            VStack(spacing: 8) {
                Text("Welcome to Billix!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Upload your first bill to start saving")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "chart.bar.fill", title: "Analyze Your Bills", description: "Get detailed insights into your spending")
                FeatureRow(icon: "dollarsign.circle.fill", title: "Find Savings", description: "Discover opportunities to reduce costs")
                FeatureRow(icon: "arrow.left.arrow.right", title: "Compare Providers", description: "See how you stack up against TruePrice™")
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Button(action: onUploadTap) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.doc.fill")
                    Text("Upload Your First Bill")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.top, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .imageScale(.large)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}
