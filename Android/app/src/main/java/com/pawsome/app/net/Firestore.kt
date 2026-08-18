package com.example.pawsome.net

import com.example.pawsome.PawsomeConfig
import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder
import java.time.Instant

class FirestoreException(message: String) : Exception(message)

class Firestore() {

    private val firebaseAuth = FirebaseAuth.getInstance()
    private val base get() = PawsomeConfig.firestoreBase
    private fun fullName(rel: String) =
        "projects/${PawsomeConfig.projectId}/databases/(default)/documents/$rel"

    suspend fun getPosts(limit: Int = 50): List<Post> = withContext(Dispatchers.IO) {
        val q = JSONObject().put(
            "structuredQuery", JSONObject()
                .put("from", JSONArray().put(JSONObject().put("collectionId", "posts")))
                .put(
                    "orderBy", JSONArray().put(
                        JSONObject()
                            .put("field", JSONObject().put("fieldPath", "timestamp"))
                            .put("direction", "DESCENDING")
                    )
                )
                .put("limit", limit)
        )
        runQuery("$base:runQuery", q).mapNotNull { (id, f) -> Post.fromFields(id, f) }
    }

    suspend fun createPost(fields: Map<String, Any?>): String = withContext(Dispatchers.IO) {
        createDoc("posts", fields).substringAfterLast('/')
    }

    suspend fun deletePost(id: String) = withContext(Dispatchers.IO) { deleteDoc("posts/$id") }

    suspend fun toggleLike(postId: String, uid: String, like: Boolean) = withContext(Dispatchers.IO) {
        val transform = JSONObject().put("fieldPath", "likes").put(
            if (like) "appendMissingElements" else "removeAllFromArray",
            JSONObject().put("values", JSONArray().put(FirestoreValue.toValue(uid)))
        )
        commitTransform("posts/$postId", transform)
    }

    suspend fun getUser(uid: String): AppUser? = withContext(Dispatchers.IO) {
        getDoc("users/$uid")?.let { AppUser.fromFields(uid, it) }
    }

    suspend fun updateUser(uid: String, fields: Map<String, Any?>) =
        withContext(Dispatchers.IO) { patchDoc("users/$uid", fields) }

    suspend fun fetchOrCreateUser(uid: String, name: String?, image: String?): AppUser =
        withContext(Dispatchers.IO) {
            getUser(uid)?.let { return@withContext it }
            val username = name ?: "User"
            patchDoc(
                "users/$uid",
                mapOf("username" to username, "profilePic" to (image ?: ""), "createdAt" to Instant.now())
            )
            AppUser(uid, username, image, 0)
        }

    // ── REST primitives ──────────────────────────────────────────────────────
    private fun runQuery(url: String, q: JSONObject): List<Pair<String, Map<String, Any?>>> {
        val text = exec("POST", url, q) ?: return emptyList()
        val arr = JSONArray(text)
        val out = ArrayList<Pair<String, Map<String, Any?>>>()
        for (i in 0 until arr.length()) {
            val doc = arr.getJSONObject(i).optJSONObject("document") ?: continue
            val id = doc.optString("name").substringAfterLast('/')
            out.add(id to FirestoreValue.parseFields(doc))
        }
        return out
    }

    private fun getDoc(rel: String): Map<String, Any?>? {
        val text = exec("GET", "$base/$rel", null) ?: return null
        return FirestoreValue.parseFields(JSONObject(text))
    }

    private fun createDoc(collection: String, fields: Map<String, Any?>): String {
        val body = JSONObject().put("fields", FirestoreValue.toFields(fields))
        val text = exec("POST", "$base/$collection", body)
        return JSONObject(text ?: "{}").optString("name")
    }

    private fun patchDoc(rel: String, fields: Map<String, Any?>) {
        val mask = fields.keys.joinToString("&") {
            "updateMask.fieldPaths=" + URLEncoder.encode(it, "UTF-8")
        }
        val body = JSONObject().put("fields", FirestoreValue.toFields(fields))
        exec("PATCH", "$base/$rel?$mask", body)
    }

    private fun deleteDoc(rel: String) { exec("DELETE", "$base/$rel", null) }

    private fun commitTransform(rel: String, transform: JSONObject) {
        val writes = JSONArray().put(
            JSONObject().put(
                "transform", JSONObject()
                    .put("document", fullName(rel))
                    .put("fieldTransforms", JSONArray().put(transform))
            )
        )
        exec("POST", "$base:commit", JSONObject().put("writes", writes))
    }

    private fun exec(method: String, url: String, body: JSONObject?): String? {
        val token = runCatching { kotlinx.coroutines.runBlocking { firebaseAuth.currentUser?.getIdToken(false)?.await() } }
            .getOrElse { throw FirestoreException("Not signed in") }
        val rb = body?.toString()?.toRequestBody(JSON)
            ?: if (method == "POST" || method == "PATCH") "".toRequestBody(JSON) else null
        val req = Request.Builder().url(url).method(method, rb)
            .header("Authorization", "Bearer ${token?.token ?: ""}").build()
        Http.client.newCall(req).execute().use { resp ->
            if (resp.code == 404) return null
            val text = resp.body?.string() ?: ""
            if (!resp.isSuccessful) throw FirestoreException(errorOf(text, resp.code))
            return text
        }
    }

    private fun errorOf(t: String, code: Int) = runCatching {
        JSONObject(t).getJSONObject("error").getString("message")
    }.getOrDefault("Firestore $code")

    companion object { private val JSON = "application/json".toMediaType() }
}
