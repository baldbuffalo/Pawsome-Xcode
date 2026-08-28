package com.example.pawsome.firebase

import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.auth.OAuthProvider
import kotlinx.coroutines.tasks.await

/**
 * Android-native Firebase Authentication adapter.
 *
 * GoogleAuth.kt remains responsible for obtaining the Google ID token. This
 * adapter hands that token to the Firebase Android Authentication SDK.
 */
class FirebaseAuth {
    private val auth = FirebaseAuth.getInstance()

    val currentUser get() = auth.currentUser
    val currentUid: String? get() = auth.currentUser?.uid

    suspend fun signInWithGoogle(googleIdToken: String) =
        auth.signInWithCredential(
            GoogleAuthProvider.getCredential(googleIdToken, null)
        ).await().user
            ?: error("Firebase returned no user after Google sign-in.")

    suspend fun signInWithTwitter(oauthToken: String, oauthTokenSecret: String) =
        auth.signInWithCredential(
            OAuthProvider.newCredentialBuilder("twitter.com")
                .setAccessToken(oauthToken)
                .setSecret(oauthTokenSecret)
                .build()
        ).await().user
            ?: error("Firebase returned no user after Twitter sign-in.")

    suspend fun refreshToken(): String {
        val user = auth.currentUser ?: error("Not signed in")
        return user.getIdToken(true).await()?.token
            ?: error("Firebase returned no ID token.")
    }

    fun signOut() = auth.signOut()
}
