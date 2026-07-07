package com.pawsome.app.auth

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import com.pawsome.app.PawsomeConfig
import com.pawsome.app.net.AuthException
import com.pawsome.app.net.Http
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.net.URLEncoder
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

data class TwitterTokens(val token: String, val tokenSecret: String)

/** X / Twitter OAuth sign-in.
 *  Uses Firebase REST API backend with callback URL for OAuth flow. */
class TwitterAuth(private val context: Context) {

    /** Start Twitter sign-in - opens browser for authorization.
     *  The callback URL https://pawsome--signin-ios.firebaseapp.com/__/auth/handler
     *  must be set in X Developer Portal. */
    suspend fun startSignIn(): Unit = withContext(Dispatchers.IO) {
        val key = PawsomeConfig.twitterConsumerKey
        val secret = PawsomeConfig.twitterConsumerSecret
        if (key.isBlank() || secret.isBlank())
            throw AuthException("No X/Twitter API key/secret configured")

        // Request token from Twitter
        val reqForm = parseForm(post(REQUEST_TOKEN, key, secret, null, emptyMap()))
        val reqToken = reqForm["oauth_token"] ?: throw AuthException("Failed to get request token")

        // Open browser for authorization - Twitter redirects to Firebase callback
        withContext(Dispatchers.Main) {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$AUTHORIZE?oauth_token=$reqToken"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    /** Get the stored request token secret (for callback processing). */
    fun getRequestSecret(): String {
        return context.getSharedPreferences("pawsome", Context.MODE_PRIVATE)
            .getString("twitter_req_secret", "") ?: ""
    }

    /** Clear stored request tokens. */
    fun clearRequestTokens() {
        context.getSharedPreferences("pawsome", Context.MODE_PRIVATE).edit()
            .remove("twitter_req_secret")
            .apply()
    }

    /** Exchange authorization verifier for access token. */
    fun exchangeToken(oauthToken: String, verifier: String, tokenSecret: String): TwitterTokens {
        val key = PawsomeConfig.twitterConsumerKey
        val secret = PawsomeConfig.twitterConsumerSecret
        
        val accForm = parseForm(
            post(ACCESS_TOKEN, key, secret, TwitterTokens(oauthToken, tokenSecret), mapOf("oauth_verifier" to verifier))
        )
        
        return TwitterTokens(
            accForm["oauth_token"] ?: throw AuthException("Failed to get access token"),
            accForm["oauth_token_secret"] ?: throw AuthException("Failed to get access token"),
        )
    }

    private fun post(url: String, key: String, secret: String, token: TwitterTokens?, extra: Map<String, String>): String {
        val oauth = sortedMapOf(
            "oauth_consumer_key" to key,
            "oauth_nonce" to UUID.randomUUID().toString().replace("-", ""),
            "oauth_signature_method" to "HMAC-SHA1",
            "oauth_timestamp" to (System.currentTimeMillis() / 1000).toString(),
            "oauth_version" to "1.0",
        )
        token?.let { if (it.token.isNotEmpty()) oauth["oauth_token"] = it.token }
        oauth.putAll(extra)
        oauth["oauth_signature"] = sign("POST", url, oauth, secret, token?.tokenSecret)

        val header = "OAuth " + oauth.filterKeys { it.startsWith("oauth_") }.toSortedMap()
            .entries.joinToString(", ") { "${enc(it.key)}=\"${enc(it.value)}\"" }

        val req = Request.Builder().url(url).post(ByteArray(0).toRequestBody(null))
            .header("Authorization", header).build()
        Http.client.newCall(req).execute().use { return it.body?.string() ?: "" }
    }

    private fun sign(method: String, url: String, params: Map<String, String>, consumerSecret: String, tokenSecret: String?): String {
        val paramString = params.entries
            .map { enc(it.key) to enc(it.value) }
            .sortedBy { it.first }
            .joinToString("&") { "${it.first}=${it.second}" }
        val base = "$method&${enc(url)}&${enc(paramString)}"
        val signingKey = "${enc(consumerSecret)}&${enc(tokenSecret ?: "")}"
        val mac = Mac.getInstance("HmacSHA1")
        mac.init(SecretKeySpec(signingKey.toByteArray(), "HmacSHA1"))
        return android.util.Base64.encodeToString(mac.doFinal(base.toByteArray()), android.util.Base64.NO_WRAP)
    }

    private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")
        .replace("+", "%20").replace("*", "%2A").replace("%7E", "~")

    private fun parseForm(body: String) = body.split("&").mapNotNull {
        val kv = it.split("=", limit = 2); if (kv.size == 2) kv[0] to kv[1] else null
    }.toMap()

    companion object {
        private const val REQUEST_TOKEN = "https://api.twitter.com/oauth/request_token"
        private const val AUTHORIZE = "https://api.twitter.com/oauth/authorize"
        private const val ACCESS_TOKEN = "https://api.twitter.com/oauth/access_token"
    }
}
