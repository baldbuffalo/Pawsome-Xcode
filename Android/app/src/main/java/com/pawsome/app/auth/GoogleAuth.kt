package com.example.pawsome.auth

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential

/** Native Android Google sign-in via Credential Manager. Returns a Google ID token. */
class GoogleAuth {
    suspend fun signIn(context: Context): String {
        val resourceId = context.resources.getIdentifier(
            "default_web_client_id",
            "string",
            context.packageName
        )
        if (resourceId == 0) {
            throw IllegalStateException("No Google web client ID configured in this build.")
        }

        val serverClientId = context.getString(resourceId)
        if (serverClientId.isBlank()) {
            throw IllegalStateException("No Google web client ID configured in this build.")
        }

        val option = GetGoogleIdOption.Builder()
            .setServerClientId(serverClientId)
            .setFilterByAuthorizedAccounts(false)
            .setAutoSelectEnabled(false)
            .build()
        val request = GetCredentialRequest.Builder()
            .addCredentialOption(option)
            .build()

        val response = CredentialManager.create(context).getCredential(context, request)
        val cred = response.credential
        if (cred is CustomCredential &&
            cred.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
        ) {
            return GoogleIdTokenCredential.createFrom(cred.data).idToken
        }

        throw IllegalStateException("Unexpected credential type from Google")
    }
}
