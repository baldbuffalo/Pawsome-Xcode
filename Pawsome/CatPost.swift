import SwiftUI
import FirebaseAuth

struct CatPostView: View {
    let post: Post
    var onLike: () -> Void
    var onComment: () -> Void
    var onDelete: (() -> Void)?

    @State private var showFullScreen = false
    @State private var showDeleteConfirm = false

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

                if post.ownerUID == Auth.auth().currentUser?.uid, onDelete != nil {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete Post", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            // Cat photo
            AsyncImage(url: URL(string: post.imageURL)) { phase in
                if let img = phase.image {
                    img.resizable().scaledToFit()
                } else if phase.error != nil {
                    Color.gray.opacity(0.2).overlay(Image(systemName: "photo").foregroundColor(.gray))
                } else {
                    Color.gray.opacity(0.1).overlay(ProgressView())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipped()
            .onTapGesture { showFullScreen = true }
            #if os(iOS)
            .fullScreenCover(isPresented: $showFullScreen) {
                FullScreenImageView(imageURL: post.imageURL)
            }
            #else
            .sheet(isPresented: $showFullScreen) {
                FullScreenImageView(imageURL: post.imageURL)
                    .frame(minWidth: 600, minHeight: 500)
            }
            #endif

            // Post details
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 16) {
                    Label(post.catName, systemImage: "pawprint.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)

                    Label("\(post.age) yrs", systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if !post.description.isEmpty {
                    Text(post.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal, 14)

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
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .confirmationDialog("Delete this post?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete?() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

// MARK: - Full Screen Image Viewer
struct FullScreenImageView: View {
    let imageURL: String
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            AsyncImage(url: URL(string: imageURL)) { phase in
                if let img = phase.image {
                    img
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1 {
                                        withAnimation { scale = 1; offset = .zero }
                                        lastScale = 1
                                        lastOffset = .zero
                                    }
                                }
                        )
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                        .onTapGesture(count: 2) {
                            withAnimation {
                                if scale > 1 {
                                    scale = 1
                                    lastScale = 1
                                    offset = .zero
                                    lastOffset = .zero
                                } else {
                                    scale = 2
                                    lastScale = 2
                                }
                            }
                        }
                } else {
                    ProgressView().tint(.white)
                }
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .padding()
            }
            .buttonStyle(.plain)
        }
    }
}
