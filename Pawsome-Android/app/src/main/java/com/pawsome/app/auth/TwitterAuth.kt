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
import java.net.InetAddress
import java.net.ServerSocket
import java.net.URLDecoder
import java.net.URLEncoder
import java.util.UUID
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

data class TwitterTokens(val token: String, val tokenSecret: String)

/** X / Twitter OAuth 1.0a sign-in over a loopback callback opened in the browser. */
class TwitterAuth {

    suspend fun signIn(context: Context): TwitterTokens = withContext(Dispatchers.IO) {
        val key = PawsomeConfig.twitterConsumerKey
        val secret = PawsomeConfig.twitterConsumerSecret
        if (key.isBlank() || secret.isBlank())
            throw AuthException("No X/Twitter API key/secret configured in this build.")

        ServerSocket(8723, 1, InetAddress.getByName("127.0.0.1")).use { server ->
            server.soTimeout = 180_000
            val callback = "http://127.0.0.1:8723/"

            val reqForm = parseForm(post(REQUEST_TOKEN, key, secret, null, mapOf("oauth_callback" to callback)))
            val reqToken = reqForm["oauth_token"] ?: throw AuthException("request_token failed")
            val reqSecret = reqForm["oauth_token_secret"] ?: ""

            withContext(Dispatchers.Main) {
                context.startActivity(
                    Intent(Intent.ACTION_VIEW, Uri.parse("$AUTHORIZE?oauth_token=${enc(reqToken)}"))
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                )
            }

            server.accept().use { socket ->
                val line = socket.getInputStream().bufferedReader().readLine()
                    ?: throw AuthException("No response from browser")
                val query = (line.split(" ").getOrNull(1) ?: "").substringAfter("?", "")
                val params = query.split("&").mapNotNull {
                    val kv = it.split("=", limit = 2); if (kv.size == 2) kv[0] to URLDecoder.decode(kv[1], "UTF-8") else null
                }.toMap()
                socket.getOutputStream().bufferedWriter().apply {
                    write("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n" +
                        "<html><body style='font-family:sans-serif;text-align:center;margin-top:64px'>" +
                        "<h2>🐾 Signed in!</h2><p>Return to Pawsome.</p></body></html>")
                    flush()
                }
                val verifier = params["oauth_verifier"] ?: throw AuthException("X/Twitter sign-in cancelled")

                val accForm = parseForm(
                    post(ACCESS_TOKEN, key, secret, TwitterTokens(reqToken, reqSecret), mapOf("oauth_verifier" to verifier))
                )
                return@withContext TwitterTokens(
                    accForm["oauth_token"] ?: throw AuthException("access_token failed"),
                    accForm["oauth_token_secret"] ?: throw AuthException("access_token failed"),
                )
            }
        }
    }

    private fun post(url: String, key: String, secret: String, token: TwitterTokens?, extra: Map<String, String>): String {
        val oauth = sortedMapOf(
            "oauth_consumer_key" to key,
            "oauth_nonce" to UUID.randomUUID().toString().replace("-", ""),
            "oauth_signature_method" to "HMAC-SHA1",
            "oauth_timestamp" to (System.currentTimeMillis() / 1000).toString(),
            "oauth_version" to "1.0",
        )
        token?.let { oauth["oauth_token"] = it.token }
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
