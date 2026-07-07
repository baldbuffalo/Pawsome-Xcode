package com.example.pawsome.auth

import android.content.Context
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.example.pawsome.PawsomeConfig
import com.example.pawsome.net.AuthException

/** Native Android Google sign-in via Credential Manager. Returns a Google ID token. */
class GoogleAuth {
    suspend fun signIn(context: Context): String {
        val serverClientId = PawsomeConfig.googleServerClientId
        if (serverClientId.isBlank())
            throw AuthException("No Google web client ID configured in this build.")

        val option = GetGoogleIdOption.Builder()
            .setServerClientId(serverClientId)
            .setFilterByAuthorizedAccounts(false)
            .setAutoSelectEnabled(false)
            .build()
        val request = GetCredentialRequest.Builder().addCredentialOption(option).build()

        val response = CredentialManager.create(context).getCredential(context, request)
        val cred = response.credential
        if (cred is CustomCredential &&
            cred.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
        ) {
            return GoogleIdTokenCredential.createFrom(cred.data).idToken
        }
        throw AuthException("Unexpected credential type from Google")
    }
}
