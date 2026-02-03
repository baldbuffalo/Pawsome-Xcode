import SwiftUI

struct HomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var currentUsername: String
    @Binding var profileImageURL: String?

    // 🔑 GLOBAL FLOW CONTROLLER
    @Binding var activeFlow: PawsomeApp.HomeFlow?

    var body: some View {
        NavigationStack {
            ZStack {
                // 🌈 BACKGROUND GRADIENT
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.25),
                        Color.blue.opacity(0.25),
                        Color.cyan.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {

                    // 🔝 HEADER
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Welcome back 👋")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(currentUsername)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .padding(.top)

                    // ➕ CREATE POST BUTTON
                    Button {
                        activeFlow = .scan
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)

                            Text("Create a new post")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.pink, .purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .shadow(color: .purple.opacity(0.4), radius: 10, y: 5)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // 📰 FEED PLACEHOLDER
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🐾 Your Feed")
                            .font(.headline)

                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                            Text("No posts yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Be the first to drop something 👀")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }

            // 🚀 NAVIGATION FLOW (FIXED & STABLE)
            .navigationDestination(
                isPresented: Binding(
                    get: { activeFlow == .scan },
                    set: { isPresented in
                        if !isPresented {
                            activeFlow = nil
                        }
                    }
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
