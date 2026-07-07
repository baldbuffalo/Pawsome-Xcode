package com.pawsome.app.auth

import android.app.Activity
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.OAuthProvider
import kotlinx.coroutines.tasks.await

/** X / Twitter sign-in using Firebase Auth SDK.
 *  Firebase handles the OAuth callback automatically. */
class TwitterAuth {

    private val firebaseAuth = FirebaseAuth.getInstance()

    /** Start Twitter sign-in using Firebase Auth SDK.
     *  Must be called from an Activity context.
     *  Returns the Firebase Auth result on success, null on failure/cancellation. */
    suspend fun startSignIn(activity: Activity) = withContext {
        val provider = OAuthProvider.newBuilder("twitter.com", firebaseAuth).build()
        
        // Check for pending result first (in case callback was received before this completes)
        firebaseAuth.pendingAuthResult?.await()?.let { return@withContext it }
        
        // Start the sign-in flow
        firebaseAuth.startActivityForSignInWithProvider(activity, provider).await()
    }
    
    private suspend fun <T> withContext(block: suspend () -> T): T {
        return kotlinx.coroutines.Dispatchers.Main.let {
            kotlinx.coroutines.withContext(it) { block() }
        }
    }
}
