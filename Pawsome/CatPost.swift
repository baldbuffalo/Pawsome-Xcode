import SwiftUI
import FirebaseAuth

struct CatPostView: View {
    let post: Post
    var onLike: () -> Void
    var onComment: () -> Void
    var onDelete: (() -> Void)?

    private var isLiked: Bool {
        post.likes.contains(Auth.auth().currentUser?.uid ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Author row
            HStack(spacing: 10) {
                AsyncImage(url: URL(string: post.ownerProfilePic)) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable().foregroundColor(.gray)
                    }
                }
                .frame(width: 38, height: 38)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.ownerUsername).font(.subheadline.weight(.semibold))
                    Text(post.timestamp.timeAgoDisplay()).font(.caption2).foregroundColor(.secondary)
                }

                Spacer()

                if post.ownerUID == Auth.auth().currentUser?.uid, let onDelete {
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "trash").font(.caption).foregroundColor(.red.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Cat photo
            AsyncImage(url: URL(string: post.imageURL)) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFill()
                } else if phase.error != nil {
                    Color.gray.opacity(0.2).overlay(Image(systemName: "photo").foregroundColor(.gray))
                } else {
                    Color.gray.opacity(0.1).overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()

            // Like / comment bar
            HStack(spacing: 20) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .secondary)
                        Text("\(post.likes.count)").font(.caption).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Button(action: onComment) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.right").foregroundColor(.secondary)
                        Text("\(post.commentCount)").font(.caption).foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // Caption
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(post.catName).font(.subheadline.weight(.semibold))
                    Text("· \(post.age) yrs").font(.caption).foregroundColor(.secondary)
                }
                if !post.description.isEmpty {
                    Text(post.description).font(.subheadline).lineLimit(3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}
