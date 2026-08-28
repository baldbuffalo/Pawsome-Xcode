package com.example.pawsome

import com.google.firebase.FirebaseApp

object PawsomeConfig {
    // Firebase credentials are supplied by google-services.json.
    // Read them from the initialized Firebase app for the custom Auth REST layer.
    val apiKey: String
        get() = requireNotNull(FirebaseApp.getInstance().options.apiKey) {
            "Firebase apiKey is missing from google-services.json"
        }

    const val githubRepo = "baldbuffalo/Pawsome-Xcode"

    val twitterConsumerKey: String get() = BuildConfig.TWITTER_CONSUMER_KEY
    val twitterConsumerSecret: String get() = BuildConfig.TWITTER_CONSUMER_SECRET
    val githubToken: String get() = BuildConfig.GITHUB_TOKEN

    const val identityBase = "https://identitytoolkit.googleapis.com/v1/accounts"

    val secureTokenUrl: String
        get() = "https://securetoken.googleapis.com/v1/token?key=$apiKey"
}
