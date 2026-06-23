package com.pawsome.app

object PawsomeConfig {
    const val projectId = "pawsome--signin-ios"
    const val apiKey = "AIzaSyBl9nk70Vocx5nTtG4ctF5HeKazSrSSfHA"
    const val githubRepo = "baldbuffalo/Pawsome-assets"

    val googleClientId: String get() = BuildConfig.GOOGLE_CLIENT_ID
    val googleClientSecret: String get() = BuildConfig.GOOGLE_CLIENT_SECRET
    val githubToken: String get() = BuildConfig.GITHUB_TOKEN

    val firestoreBase: String
        get() = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents"
    const val identityBase = "https://identitytoolkit.googleapis.com/v1/accounts"
    val secureTokenUrl: String get() = "https://securetoken.googleapis.com/v1/token?key=$apiKey"
}
