package com.pawsome.app.auth

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

/** Global holder for Twitter OAuth state - survives activity recreation */
object TwitterAuthHolder {
    var pendingToken: String? = null
    var pendingSecret: String? = null
}

/** X / Twitter OAuth 1.0a sign-in using custom URL scheme callback. */
class TwitterAuth(private val context: Context) {

    /** Start the Twitter sign-in flow - opens browser and returns immediately.
     *  The actual result comes through handleCallback() called from the activity. */
    suspend fun startSignIn() = withContext(Dispatchers.IO) {
        val key = PawsomeConfig.twitterConsumerKey
        val secret = PawsomeConfig.twitterConsumerSecret
        if (key.isBlank() || secret.isBlank())
            throw AuthException("No X/Twitter API key/secret configured in this build.")

        // Use custom URL scheme for callback - more reliable on Android than localhost
        val callback = "pawsome://twitter-callback"
        
        val reqForm = parseForm(post(REQUEST_TOKEN, key, secret, null, mapOf("oauth_callback" to callback)))
        val reqToken = reqForm["oauth_token"] ?: throw AuthException("request_token failed")
        val reqSecret = reqForm["oauth_token_secret"] ?: ""
        
        // Store for callback in global holder
        TwitterAuthHolder.pendingToken = reqToken
        TwitterAuthHolder.pendingSecret = reqSecret

        withContext(Dispatchers.Main) {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse("$AUTHORIZE?oauth_token=${enc(reqToken)}"))
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
        // Return immediately, callback will handle the result
    }

    /** Called from MainActivity when the custom URL scheme is received.
     *  Returns the tokens if successful, null if callback doesn't match. */
    fun handleCallback(uri: Uri): TwitterTokens? {
        val verifier = uri.getQueryParameter("oauth_verifier")
        val oauthToken = uri.getQueryParameter("oauth_token")
        
        if (verifier == null) {
            android.util.Log.e("TwitterAuth", "No verifier in callback")
            return null
        }
        
        if (oauthToken == null) {
            android.util.Log.e("TwitterAuth", "No oauth_token in callback")
            return null
        }
        
        // Get the token secret from holder, or use empty string if cleared
        val tokenSecret = TwitterAuthHolder.pendingSecret ?: ""
        
        android.util.Log.d("TwitterAuth", "Processing callback: token=${oauthToken.take(10)}..., verifier=${verifier.take(10)}...")
        
        // Clear global state
        TwitterAuthHolder.pendingToken = null
        TwitterAuthHolder.pendingSecret = null
        
        // Exchange for access token (synchronously since we're already on the callback thread)
        val key = PawsomeConfig.twitterConsumerKey
        val appSecret = PawsomeConfig.twitterConsumerSecret
        
        val accForm = parseForm(
            post(ACCESS_TOKEN, key, appSecret, TwitterTokens(oauthToken, tokenSecret), mapOf("oauth_verifier" to verifier))
        )
        
        return TwitterTokens(
            accForm["oauth_token"] ?: throw AuthException("access_token failed"),
            accForm["oauth_token_secret"] ?: throw AuthException("access_token failed"),
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
