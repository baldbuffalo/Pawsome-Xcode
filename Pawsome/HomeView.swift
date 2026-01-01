import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?

    // 🔑 GLOBAL FLOW (from PawsomeApp)
    @Binding var activeFlow: PawsomeApp.HomeFlow?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // 🔝 TOP BAR
                HStack {
                    Text("Welcome, \(currentUsername)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    if let urlString = profileImageURL,
                       let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                // ➕ CREATE POST BUTTON
                Button {
                    activeFlow = .scan // 🚀 OPEN SCAN FLOW
                } label: {
                    Label("Create a new post", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .padding(.horizontal)

                // 📰 FEED PLACEHOLDER
                ScrollView {
                    VStack(spacing: 20) {
                        Text("🐾 Your Feed")
                            .font(.headline)
                            .padding(.top, 10)

                        Text("No posts yet 👀")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                    .padding()
                }

                Spacer()
            }
            // 🧠 FLOW-DRIVEN NAVIGATION
            .navigationDestination(
                isPresented: Binding(
                    get: { activeFlow == .scan },
                    set: { if !$0 { activeFlow = nil } }
                )
            ) {
                ScanView(
                    username: currentUsername,
                    onPostCreated: {
                        activeFlow = nil // ✅ CLOSE FLOW AFTER POST
                    },
                    activeHomeFlow: $activeFlow // 🔑 REQUIRED FOR TAB TITLE SWITCH
                )
            }
        }
    }
}
