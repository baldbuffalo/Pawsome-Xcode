package com.example.pawsome.auth

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException

@Suppress("DEPRECATION")
class GoogleAuth {
    companion object {
        const val REQUEST_CODE = 9001
    }

    private fun serverClientId(context: Context): String {
        val resourceId = context.resources.getIdentifier(
            "default_web_client_id",
            "string",
            context.packageName,
        )
        if (resourceId == 0) {
            throw IllegalStateException("No Google web client ID configured in this build.")
        }
        return context.getString(resourceId).takeIf { it.isNotBlank() }
            ?: throw IllegalStateException("No Google web client ID configured in this build.")
    }

    fun startSignIn(context: Context) {
        val activity = context as? Activity
            ?: throw IllegalStateException("Google sign-in requires an Activity context.")

        val options = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .requestIdToken(serverClientId(context))
            .build()

        val client = GoogleSignIn.getClient(activity, options)

        // Clear any previously selected Google account before starting a new
        // interactive sign-in. This prevents a stale/rejected Google auth
        // session from being reused and producing BAD_AUTHENTICATION.
        client.signOut().addOnCompleteListener {
            activity.startActivityForResult(client.signInIntent, REQUEST_CODE)
        }
    }

    fun getAccountFromResult(data: Intent?): GoogleSignInAccount {
        if (data == null) {
            throw IllegalStateException("Google sign-in returned no result.")
        }
        return try {
            GoogleSignIn.getSignedInAccountFromIntent(data).getResult(ApiException::class.java)
        } catch (e: ApiException) {
            throw IllegalStateException("Google sign-in failed (status ${e.statusCode}).", e)
        }
    }
}
