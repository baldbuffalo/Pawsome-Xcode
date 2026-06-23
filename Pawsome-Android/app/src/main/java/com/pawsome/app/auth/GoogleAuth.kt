package com.pawsome.app.auth

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Base64
import androidx.browser.customtabs.CustomTabsIntent
import com.pawsome.app.PawsomeConfig
import com.pawsome.app.net.AuthException
import com.pawsome.app.net.Http
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.FormBody
import okhttp3.Request
import org.json.JSONObject
import java.net.InetAddress
import java.net.ServerSocket
import java.net.URLDecoder
import java.net.URLEncoder
import java.security.MessageDigest
import java.security.SecureRandom

/** Native Google sign-in via the loopback + PKCE flow, opened in a Custom Tab. */
class GoogleAuth(private val context: Context) {

    suspend fun signIn(): String = withContext(Dispatchers.IO) {
        val clientId = PawsomeConfig.googleClientId
        if (clientId.isBlank()) throw AuthException("No Google client ID configured in this build.")

        val verifier = randomUrlSafe(64)
        val challenge = base64Url(sha256(verifier.toByteArray(Charsets.US_ASCII)))
        val state = randomUrlSafe(16)

        ServerSocket(0, 1, InetAddress.getByName("127.0.0.1")).use { server ->
            server.soTimeout = 180_000
            val redirect = "http://127.0.0.1:${server.localPort}"
            val authUrl = "https://accounts.google.com/o/oauth2/v2/auth" +
                "?client_id=${enc(clientId)}&redirect_uri=${enc(redirect)}" +
                "&response_type=code&scope=${enc("openid email profile")}" +
                "&code_challenge=$challenge&code_challenge_method=S256" +
                "&state=$state&access_type=offline&prompt=select_account"

            withContext(Dispatchers.Main) { launchTab(authUrl) }

            server.accept().use { socket ->
                val line = socket.getInputStream().bufferedReader().readLine()
                    ?: throw AuthException("No response from browser")
                val query = (line.split(" ").getOrNull(1) ?: "").substringAfter("?", "")
                val params = query.split("&").mapNotNull {
                    val kv = it.split("=", limit = 2)
                    if (kv.size == 2) kv[0] to URLDecoder.decode(kv[1], "UTF-8") else null
                }.toMap()

                val html = "<html><body style='font-family:sans-serif;text-align:center;margin-top:64px'>" +
                    "<h2>🐾 Signed in!</h2><p>You can return to Pawsome.</p></body></html>"
                socket.getOutputStream().bufferedWriter().apply {
                    write("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r\n$html")
                    flush()
                }

                params["error"]?.let { throw AuthException("Sign-in cancelled: $it") }
                if (params["state"] != state) throw AuthException("State mismatch")
                val code = params["code"] ?: throw AuthException("No authorization code")
                return@withContext exchange(code, verifier, redirect, clientId)
            }
        }
    }

    private fun exchange(code: String, verifier: String, redirect: String, clientId: String): String {
        val form = FormBody.Builder()
            .add("client_id", clientId).add("code", code)
            .add("code_verifier", verifier).add("grant_type", "authorization_code")
            .add("redirect_uri", redirect)
        PawsomeConfig.googleClientSecret.takeIf { it.isNotBlank() }?.let { form.add("client_secret", it) }

        val req = Request.Builder().url("https://oauth2.googleapis.com/token").post(form.build()).build()
        Http.client.newCall(req).execute().use { resp ->
            val text = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw AuthException("Token exchange failed: $text")
            return JSONObject(text).optString("id_token").ifBlank { throw AuthException("No id_token") }
        }
    }

    private fun launchTab(url: String) {
        CustomTabsIntent.Builder().build().apply {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }.launchUrl(context, Uri.parse(url))
    }

    private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")
    private fun sha256(b: ByteArray) = MessageDigest.getInstance("SHA-256").digest(b)
    private fun base64Url(b: ByteArray) =
        Base64.encodeToString(b, Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP)
    private fun randomUrlSafe(bytes: Int) = base64Url(ByteArray(bytes).also { SecureRandom().nextBytes(it) })
}
