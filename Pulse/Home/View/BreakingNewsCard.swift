import SwiftUI

struct BreakingNewsCard: View {
    let item: ArticleViewItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                if let imageURL = item.imageURL {
                    CachedAsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 280, height: 200)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(.quaternary)
                            .overlay {
                                ProgressView()
                            }
                    }
                } else {
                    Rectangle()
                        .fill(.quaternary)
                        .overlay {
                            Image(systemName: "newspaper")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("BREAKING")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.red)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        Spacer()
                    }

                    Text(item.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    HStack {
                        Text(item.sourceName)
                            .font(.caption)
                            .fontWeight(.medium)

                        Text("•")
                            .font(.caption)

                        Text(item.formattedDate)
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding()
            }
            .frame(width: 280, height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    BreakingNewsCard(
        item: ArticleViewItem(
            from: Article(
                title: "Breaking: Major News Event Happening Right Now",
                source: ArticleSource(id: nil, name: "News Source"),
                url: "https://example.com",
                imageURL: "https://picsum.photos/300/200",
                publishedAt: Date()
            )
        ),
        onTap: {}
    )
    .padding()
}
