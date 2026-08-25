package com.example.pawsome

object PawsomeConfig {
    // Firebase credentials are supplied by google-services.json.
    const val projectId = ""
    const val apiKey = ""
    const val githubRepo = "baldbuffalo/Pawsome-assets"

    val twitterConsumerKey: String get() = BuildConfig.TWITTER_CONSUMER_KEY
    val twitterConsumerSecret: String get() = BuildConfig.TWITTER_CONSUMER_SECRET
    val githubToken: String get() = BuildConfig.GITHUB_TOKEN

    val firestoreBase: String
        get() = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents"
    const val identityBase = "https://identitytoolkit.googleapis.com/v1/accounts"
    val secureTokenUrl: String get() = "https://securetoken.googleapis.com/v1/token?key=$apiKey"
}
