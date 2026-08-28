import FirebaseAuth

/// Apple-native Firebase Authentication adapter for iOS and macOS.
public final class PawsomeFirebaseAuth {
    public static let shared = PawsomeFirebaseAuth()

    private let auth = Auth.auth()

    private init() {}

    public var currentUser: User? { auth.currentUser }
    public var currentUid: String? { auth.currentUser?.uid }

    public func signInWithGoogle(idToken: String, accessToken: String? = nil) async throws -> User {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        let result = try await auth.signIn(with: credential)
        return result.user
    }

    public func signInWithTwitter(
        accessToken: String,
        secret: String
    ) async throws -> User {
        let credential = OAuthProvider.credential(
            withProviderID: "twitter.com",
            accessToken: accessToken,
            secret: secret
        )
        let result = try await auth.signIn(with: credential)
        return result.user
    }

    public func getIDToken(forceRefresh: Bool = false) async throws -> String {
        let user = auth.currentUser
            ?? NSError(domain: "PawsomeFirebaseAuth", code: 1,
                       userInfo: [NSLocalizedDescriptionKey: "Not signed in"])
        return try await user.getIDToken(forcingRefresh: forceRefresh)
    }

    public func signOut() throws {
        try auth.signOut()
    }
}
