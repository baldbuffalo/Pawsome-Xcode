import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?   // still passed, just not used

    // 🔑 GLOBAL FLOW (from PawsomeApp)
    @Binding var activeFlow: PawsomeApp.HomeFlow?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // 🔝 TOP BAR (NO PROFILE PIC)
                HStack {
                    Text("Welcome, \(currentUsername)")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top)

                // ➕ CREATE POST BUTTON
                Button {
                    activeFlow = .scan
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
            // 🚀 FLOW-DRIVEN NAVIGATION
            .navigationDestination(
                isPresented: Binding(
                    get: { activeFlow == .scan },
                    set: { if !$0 { activeFlow = nil } }
                )
            ) {
                ScanView(
                    activeHomeFlow: $activeFlow,
                    username: currentUsername
                )
            }
        }
    }
}
