import SwiftUI
import FirebaseAuth

struct CatPostView: View {
    let post: Post
    var onLike: () -> Void
    var onComment: () -> Void
    var onDelete: (() -> Void)?
    @EnvironmentObject private var appState: PawsomeApp.AppState

    @State private var showFullScreen = false
    @State private var showDeleteConfirm = false

    private var isLiked: Bool { post.likes.contains(Auth.auth().currentUser?.uid ?? "") }
    private var statusColor: Color {
        switch post.status {
        case .LOST: return .red
        case .FOUND: return .green
        case .REUNITED: return .yellow
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: post.profilePic)) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { Image(systemName: "person.circle.fill").resizable().foregroundStyle(.gray) }
                }
                .frame(width: 44, height: 44).clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(post.username).font(.subheadline.weight(.semibold))
                        Text("\(post.status.emoji) \(post.status.displayName)")
                            .font(.caption2.weight(.semibold)).foregroundStyle(statusColor)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(statusColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                    HStack(spacing: 3) {
                        Text(post.timestamp.timeAgoDisplay()).font(.caption).foregroundStyle(.secondary)
                        if !post.location.isEmpty {
                            Text("•").foregroundStyle(.secondary)
                            Image(systemName: "location.fill").font(.caption2).foregroundStyle(.secondary)
                            Text(post.location).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                }
                Spacer()
                if post.userID == appState.currentUserID, onDelete != nil {
                    Button { showDeleteConfirm = true } label: {
                        Image(systemName: "trash").foregroundStyle(.red)
                    }.buttonStyle(.plain)
                }
            }
            .padding(14)

            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: post.imageURL)) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else if phase.error != nil { Color.gray.opacity(0.2).overlay(Image(systemName: "photo").foregroundStyle(.gray)) }
                    else { Color.gray.opacity(0.1).overlay(ProgressView()) }
                }
                .frame(maxWidth: .infinity).frame(height: 280).clipped()
                .contentShape(Rectangle()).onTapGesture { showFullScreen = true }

                Text(post.status.displayName.uppercased())
                    .font(.caption2.bold()).foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(statusColor, in: RoundedRectangle(cornerRadius: 10)).padding(12)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(post.catName).font(.headline.bold())
                    if !post.age.isEmpty {
                        Text("\(post.age) yrs").font(.caption).foregroundStyle(.purple)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                if !post.description.isEmpty {
                    Text(post.description).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)

            HStack(spacing: 12) {
                Button(action: onLike) {
                    Label("\(post.likes.count) likes", systemImage: isLiked ? "heart.fill" : "heart")
                        .foregroundStyle(isLiked ? .red : .secondary).frame(minHeight: 40)
                }.buttonStyle(.bordered)
                Button(action: onComment) {
                    Label("\(post.commentCount) comments", systemImage: "bubble.right").frame(minHeight: 40)
                }.buttonStyle(.bordered)
                Spacer()
            }
            .padding(.horizontal, 8).padding(.bottom, 8)
        }
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20)).shadow(radius: 4, y: 2)
        .fullScreenCover(isPresented: $showFullScreen) { FullScreenImageView(imageURL: post.imageURL) }
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FullScreenImageView: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            AsyncImage(url: URL(string: imageURL)) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFit().scaleEffect(scale).offset(offset)
                        .gesture(MagnificationGesture().onChanged { scale = min(max($0, 1), 5) })
                        .simultaneousGesture(DragGesture().onChanged { offset = $0.translation })
                        .onTapGesture(count: 2) { withAnimation { if scale > 1 { scale = 1; offset = .zero } else { scale = 2.5 } } }
                } else { ProgressView().tint(.white) }
            }
            Button { dismiss() } label: { Image(systemName: "xmark.circle.fill").font(.title).foregroundStyle(.white).padding() }
            .buttonStyle(.plain)
        }
    }
}
