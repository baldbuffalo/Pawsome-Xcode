// PawsomeApp.swift
import SwiftUI
import FirebaseCore

@main
struct PawsomeApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    #endif

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.isLoggedIn {
                MainTabView(appState: appState)
            } else {
                LoginView(
                    isLoggedIn: $appState.isLoggedIn,
                    username: $appState.currentUsername,
                    profileImage: $appState.profileImageURL
                )
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        appState.checkLoginState()
                    }
                }
            }
        }
    }

    final class AppState: ObservableObject {
        @Published var isLoggedIn = false
        @Published var currentUsername = ""
        @Published var profileImageURL: String? = nil

        func checkLoginState() {
            isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
            currentUsername = UserDefaults.standard.string(forKey: "username") ?? "User\(Int.random(in: 1000...9999))"
            profileImageURL = UserDefaults.standard.string(forKey: "profileImageURL")
        }
    }

    struct MainTabView: View {
        @ObservedObject var appState: AppState

        var body: some View {
            TabView {
                HomeTab()
                    .tabItem { Label("Home", systemImage: "house") }

                ScanTab()
                    .tabItem { Label("Scan", systemImage: "qrcode.viewfinder") }

                ProfileTab()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
        }

        @ViewBuilder private func HomeTab() -> some View {
            HomeView(
                isLoggedIn: $appState.isLoggedIn,
                currentUsername: $appState.currentUsername,
                profileImageURL: $appState.profileImageURL,
                onPostCreated: {}
            )
        }

        @ViewBuilder private func ScanTab() -> some View {
            ScanView(
                username: appState.currentUsername,
                onPostCreated: { print("ScanView post created callback") }
            )
        }

        @ViewBuilder private func ProfileTab() -> some View {
            ProfileView(
                isLoggedIn: $appState.isLoggedIn,
                currentUsername: $appState.currentUsername,
                profileImageURL: $appState.profileImageURL
            )
        }
    }
}
