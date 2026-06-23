package com.pawsome.app.net

import android.util.Base64
import com.pawsome.app.PawsomeConfig
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.Headers
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

class GitHubException(message: String) : Exception(message)

class GitHubUploader {
    private val repo = PawsomeConfig.githubRepo
    val hasToken get() = PawsomeConfig.githubToken.isNotBlank()

    suspend fun uploadImage(bytes: ByteArray, fileName: String, folder: String): String =
        withContext(Dispatchers.IO) { upload(bytes, "$folder/$fileName", "Upload $fileName") }

    suspend fun deleteFile(path: String) = withContext(Dispatchers.IO) {
        val sha = fileSha(path) ?: return@withContext
        val body = JSONObject().put("message", "Delete $path").put("sha", sha)
        val req = Request.Builder().url(contentsUrl(path))
            .delete(body.toString().toRequestBody(JSON)).headers(headers()).build()
        Http.client.newCall(req).execute().use { if (!it.isSuccessful) throw GitHubException("Delete failed") }
    }

    private fun upload(data: ByteArray, path: String, message: String): String {
        val body = JSONObject()
            .put("message", message)
            .put("content", Base64.encodeToString(data, Base64.NO_WRAP))
        fileSha(path)?.let { body.put("sha", it) }
        val req = Request.Builder().url(contentsUrl(path))
            .put(body.toString().toRequestBody(JSON)).headers(headers()).build()
        Http.client.newCall(req).execute().use { resp ->
            val text = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw GitHubException(msgOf(text, resp.code))
            return JSONObject(text).getJSONObject("content").getString("download_url")
        }
    }

    private fun fileSha(path: String): String? {
        val req = Request.Builder().url(contentsUrl(path)).get().headers(headers()).build()
        Http.client.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) return null
            return runCatching { JSONObject(resp.body?.string() ?: "").optString("sha").ifBlank { null } }
                .getOrNull()
        }
    }

    private fun contentsUrl(path: String) = "https://api.github.com/repos/$repo/contents/$path"
    private fun headers() = Headers.Builder()
        .add("Authorization", "token ${PawsomeConfig.githubToken}")
        .add("Accept", "application/vnd.github.v3+json")
        .add("User-Agent", "Pawsome-Android")
        .build()

    private fun msgOf(t: String, c: Int) =
        runCatching { JSONObject(t).optString("message").ifBlank { "HTTP $c" } }.getOrDefault("HTTP $c")

    companion object { private val JSON = "application/json".toMediaType() }
}
