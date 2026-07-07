package com.pawsome.app.auth

import android.app.Activity
import com.pawsome.app.net.AuthException

/** X / Twitter sign-in using Firebase Auth SDK. */
class TwitterAuth(private val activity: Activity) {

    private val firebaseAuth = com.google.firebase.auth.FirebaseAuth.getInstance()

    /** Start Twitter sign-in using Firebase Auth SDK. */
    fun startSignIn(onComplete: (String?, String?) -> Unit) {
        val provider = com.google.firebase.auth.OAuthProvider.newBuilder("twitter.com", firebaseAuth)
        
        firebaseAuth.startActivityForSignInWithProvider(activity, provider.build()) { result ->
            if (result != null) {
                val user = result.user
                // Get Twitter tokens from the credential
                val credential = result.credential
                // Extract tokens from the credential if available
                val accessToken = credential?.accessToken
                val tokenSecret = credential?.secret
                onComplete(accessToken, tokenSecret)
            } else {
                onComplete(null, null)
            }
        }
    }
}
