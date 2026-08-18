package com.example.pawsome.net

import com.example.pawsome.PawsomeConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

data class Session(
    val uid: String,
    var idToken: String,
    var refreshToken: String,
    var expiresAt: Long,
    val displayName: String?,
    val photoUrl: String?,
)

class AuthException(message: String) : Exception(message)

class FirebaseAuth {
    var current: Session? = null
        private set

    suspend fun signInWithGoogle(googleIdToken: String): Session = withContext(Dispatchers.IO) {
        val body = JSONObject()
            .put("postBody", "id_token=$googleIdToken&providerId=google.com")
            .put("requestUri", "http://localhost")
            .put("returnSecureToken", true)
            .put("returnIdpCredential", true)
        val json = post("${PawsomeConfig.identityBase}:signInWithIdp?key=${PawsomeConfig.apiKey}", body)
        Session(
            json.getString("localId"),
            json.getString("idToken"),
            json.getString("refreshToken"),
            expiry(json.optString("expiresIn")),
            json.optString("displayName").ifBlank { null },
            json.optString("photoUrl").ifBlank { null },
        ).also { current = it }
    }

    suspend fun signInWithTwitter(accessToken: String, tokenSecret: String): Session = withContext(Dispatchers.IO) {
        val enc = { s: String -> java.net.URLEncoder.encode(s, "UTF-8") }
        val body = JSONObject()
            .put("postBody", "access_token=${enc(accessToken)}&oauth_token_secret=${enc(tokenSecret)}&providerId=twitter.com")
            .put("requestUri", "http://localhost")
            .put("returnSecureToken", true)
            .put("returnIdpCredential", true)
        val json = post("${PawsomeConfig.identityBase}:signInWithIdp?key=${PawsomeConfig.apiKey}", body)
        Session(
            json.getString("localId"),
            json.getString("idToken"),
            json.getString("refreshToken"),
            expiry(json.optString("expiresIn")),
            json.optString("displayName").ifBlank { null },
            json.optString("photoUrl").ifBlank { null },
        ).also { current = it }
    }

    suspend fun restore(refreshToken: String): Session? = withContext(Dispatchers.IO) {
        runCatching { refresh(refreshToken).also { current = it } }.getOrNull()
    }

    suspend fun validIdToken(): String = withContext(Dispatchers.IO) {
        val c = current ?: throw AuthException("Not signed in")
        if (System.currentTimeMillis() < c.expiresAt - 300_000) return@withContext c.idToken
        val r = refresh(c.refreshToken)
        c.idToken = r.idToken; c.refreshToken = r.refreshToken; c.expiresAt = r.expiresAt
        c.idToken
    }

    fun signOut() { current = null }

    private fun refresh(rt: String): Session {
        val form = FormBody.Builder().add("grant_type", "refresh_token").add("refresh_token", rt).build()
        val req = Request.Builder().url(PawsomeConfig.secureTokenUrl).post(form).build()
        Http.client.newCall(req).execute().use { resp ->
            val text = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw AuthException(errorOf(text))
            val j = JSONObject(text)
            return Session(
                j.getString("user_id"), j.getString("id_token"), j.getString("refresh_token"),
                expiry(j.optString("expires_in")), current?.displayName, current?.photoUrl
            )
        }
    }

    private fun post(url: String, body: JSONObject): JSONObject {
        val req = Request.Builder().url(url).post(body.toString().toRequestBody(JSON)).build()
        Http.client.newCall(req).execute().use { resp ->
            val text = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw AuthException(errorOf(text))
            return JSONObject(text)
        }
    }

    private fun expiry(sec: String?) = System.currentTimeMillis() + ((sec?.toLongOrNull() ?: 3600L) * 1000)
    private fun errorOf(t: String) = runCatching {
        JSONObject(t).getJSONObject("error").getString("message")
    }.getOrDefault("Sign-in failed")

    companion object { private val JSON = "application/json".toMediaType() }
}
