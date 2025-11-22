import SwiftUI

/// Full article detail view for Bill Briefs
struct BillBriefDetailView: View {
    let brief: BillBrief
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Hero image
                Rectangle()
                    .fill(Color.billixLightGreen)
                    .frame(height: 250)
                    .overlay(
                        VStack {
                            Text(brief.categoryIcon)
                                .font(.system(size: 80))
                        }
                    )
                    .clipped()

                VStack(alignment: .leading, spacing: 16) {
                    // Category tag
                    HStack(spacing: 6) {
                        Text(brief.categoryIcon)
                            .font(.system(size: 18))

                        Text(brief.category)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.billixMediumGreen)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    // Title
                    Text(brief.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.billixDarkGreen)

                    // Meta info
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(.billixMediumGreen)

                            Text("\(brief.readTime) min read")
                                .font(.system(size: 13))
                                .foregroundColor(.billixMediumGreen)
                        }

                        Text("•")
                            .foregroundColor(.billixMediumGreen.opacity(0.5))

                        Text(brief.publishedDate, style: .date)
                            .font(.system(size: 13))
                            .foregroundColor(.billixMediumGreen)
                    }

                    Divider()
                        .padding(.vertical, 8)

                    // Excerpt (if available)
                    if let excerpt = brief.excerpt {
                        Text(excerpt)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.billixDarkGreen)
                            .padding(.vertical, 8)
                    }

                    // Full content
                    Text(brief.content)
                        .font(.system(size: 16))
                        .foregroundColor(.billixDarkGreen)
                        .lineSpacing(6)

                    Divider()
                        .padding(.vertical, 16)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            // TODO: Implement bookmark
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }) {
                            HStack {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 14))

                                Text("Bookmark Article")
                                    .font(.system(size: 15, weight: .medium))

                                Spacer()
                            }
                            .foregroundColor(.billixLoginTeal)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .background(Color.billixLoginTeal.opacity(0.1))
                            .cornerRadius(12)
                        }

                        ShareLink(item: brief.title, message: Text(brief.excerpt ?? "")) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 14))

                                Text("Share Article")
                                    .font(.system(size: 15, weight: .medium))

                                Spacer()
                            }
                            .foregroundColor(.billixDarkGreen)
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            .billixCard(cornerRadius: 12)
                        }
                    }

                    // Related articles section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("More Articles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.billixDarkGreen)
                            .padding(.top, 8)

                        ForEach(BillBrief.mockBriefs.filter { $0.id != brief.id }.prefix(2)) { relatedBrief in
                            NavigationLink(destination: BillBriefDetailView(brief: relatedBrief)) {
                                RelatedArticleRow(brief: relatedBrief)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .background(Color.white)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RelatedArticleRow: View {
    let brief: BillBrief

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(brief.categoryIcon)
                .font(.system(size: 32))
                .frame(width: 60, height: 60)
                .background(Color.billixLightGreen)
                .cornerRadius(12)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(brief.category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.billixMediumGreen)
                    .textCase(.uppercase)

                Text(brief.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.billixDarkGreen)
                    .lineLimit(2)

                Text("\(brief.readTime) min read")
                    .font(.system(size: 12))
                    .foregroundColor(.billixMediumGreen)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.billixMediumGreen)
        }
        .padding(12)
        .billixCard(cornerRadius: 12)
    }
}

#Preview {
    NavigationView {
        BillBriefDetailView(brief: .mockBrief)
    }
}
