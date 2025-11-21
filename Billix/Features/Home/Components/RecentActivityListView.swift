import SwiftUI

struct RecentActivityListView: View {
    let activities: [RecentActivity]
    let onActivityTap: (RecentActivity) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal)

            if activities.isEmpty {
                EmptyActivityView()
            } else {
                ForEach(activities.prefix(5)) { activity in
                    ActivityRow(activity: activity)
                        .onTapGesture {
                            onActivityTap(activity)
                        }
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct ActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.type.icon)
                .foregroundColor(activity.type.color)
                .imageScale(.medium)
                .frame(width: 36, height: 36)
                .background(Circle().fill(activity.type.color.opacity(0.15)))

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(activity.type.actionText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(activity.billName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    Text(activity.relativeTimestamp)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if activity.status == .processing {
                        HStack(spacing: 4) {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Processing")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    } else if activity.status == .failed {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .imageScale(.small)
                            Text("Failed")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                    }

                    if let amount = activity.amount, activity.type == .saved {
                        Text("• $\(String(format: "%.0f", amount)) saved")
                            .font(.caption)
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .imageScale(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct EmptyActivityView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.5))

            Text("No recent activity")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Upload your first bill to get started")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
}
