package com.example.pawsome

import com.google.firebase.FirebaseApp

object PawsomeConfig {
    // Firebase credentials are supplied by google-services.json.
    // Read them from the initialized Firebase app instead of duplicating them here.
    val projectId: String
        get() = requireNotNull(FirebaseApp.getInstance().options.projectId) {
            "Firebase projectId is missing from google-services.json"
        }

    val apiKey: String
        get() = requireNotNull(FirebaseApp.getInstance().options.apiKey) {
            "Firebase apiKey is missing from google-services.json"
        }

    // Main source repository. Pawsome-assets is used separately only for image storage.
    const val githubRepo = "baldbuffalo/Pawsome-Xcode"

    val twitterConsumerKey: String get() = BuildConfig.TWITTER_CONSUMER_KEY
    val twitterConsumerSecret: String get() = BuildConfig.TWITTER_CONSUMER_SECRET
    val githubToken: String get() = BuildConfig.GITHUB_TOKEN

    val firestoreBase: String
        get() = "https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents"

    const val identityBase = "https://identitytoolkit.googleapis.com/v1/accounts"

    val secureTokenUrl: String
        get() = "https://securetoken.googleapis.com/v1/token?key=$apiKey"
}
