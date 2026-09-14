import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ProfileView: View {
    @ObservedObject var appState: PawsomeApp.AppState
    @State private var posts: [Post] = []
    @State private var showAbout = false
    @State private var showHelp = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer(minLength: 24)

                ZStack {
                    Circle().fill(Color.purple.opacity(0.14)).frame(width: 120, height: 120)
                    AsyncImage(url: URL(string: appState.profileImageURL ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            Image(systemName: "person.fill").font(.system(size: 52)).foregroundStyle(.purple.opacity(0.65))
                        }
                    }
                    .frame(width: 112, height: 112)
                    .clipShape(Circle())
                }

                Spacer(minLength: 16)
                Text(appState.currentUsername.isEmpty ? "User" : appState.currentUsername)
                    .font(.largeTitle.bold())
                Text("@\(appState.currentUsername.isEmpty ? "user" : appState.currentUsername)")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 32)

                HStack {
                    ProfileStat(count: posts.count, label: "Posts")
                    ProfileStat(count: posts.reduce(0) { $0 + $1.likes.count }, label: "Likes")
                    ProfileStat(count: appState.currentUserID ?? 0, label: "Member #")
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 24)

                SettingsCard {
                    SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage your notification preferences") { }
                    Divider().padding(.horizontal)
                    SettingsRow(icon: "pawprint.fill", title: "My Posts", subtitle: "\(posts.filter { $0.userID == appState.currentUserID }.count) posts") { }
                    Divider().padding(.horizontal)
                    SettingsRow(icon: "heart.fill", title: "Liked Posts", subtitle: "Posts you've liked") { }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 16)

                SettingsCard {
                    SettingsRow(icon: "info.circle.fill", title: "About Pawsome", subtitle: "Version 1.0.0") { showAbout = true }
                    Divider().padding(.horizontal)
                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", subtitle: "Get help or report issues") { showHelp = true }
                }
                .padding(.horizontal, 20)

                Spacer(minLength: 32)

                Button(role: .destructive) {
                    appState.logout()
                } label: {
                    Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                Spacer(minLength: 24)
            }
        }
        .background(Color(.systemBackground))
        .onAppear { loadPosts() }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showHelp) { HelpView() }
    }

    private func loadPosts() {
        Firestore.firestore().collection("posts").order(by: "PostedAt", descending: true).getDocuments { snapshot, _ in
            posts = snapshot?.documents.compactMap { Post(id: $0.documentID, data: $0.data()) } ?? []
        }
    }
}

private struct ProfileStat: View {
    let count: Int
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)").font(.title2.bold()).foregroundStyle(.purple)
            Text(label).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SettingsCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(spacing: 0) { content }
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon).frame(width: 24).foregroundStyle(.purple)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.body.weight(.medium)).foregroundStyle(.primary)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "pawprint.fill").font(.system(size: 54)).foregroundStyle(.purple)
                Text("Pawsome").font(.largeTitle.bold())
                Text("Find. Help. Reunite. 🐱").foregroundStyle(.secondary)
                Text("Version 1.0.0").font(.headline)
                Spacer()
                Text("Made with ❤️ for cats everywhere").font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("About Pawsome")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Need help with Pawsome?").font(.title3.bold())
                Text("If you're experiencing issues or have questions, please report them on GitHub.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                Link(destination: URL(string: "https://github.com/baldbuffalo/Pawsome-Xcode/issues")!) {
                    Label("Report an Issue on GitHub", systemImage: "ladybug.fill")
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding(20)
            .navigationTitle("Help & Support")
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
        }
    }
}
