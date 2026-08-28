package com.example.pawsome.net

import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.google.firebase.firestore.DocumentSnapshot
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.time.Instant

class FirestoreException(message: String) : Exception(message)

class Firestore {

    private val db = FirebaseFirestore.getInstance()

    suspend fun getPosts(limit: Int = 50): List<Post> = withContext(Dispatchers.IO) {
        db.collection("posts")
            .orderBy("timestamp", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .get()
            .await()
            .documents
            .mapNotNull { Post.fromDocument(it) }
    }

    suspend fun createPost(fields: Map<String, Any?>): String = withContext(Dispatchers.IO) {
        val ref = db.collection("posts").document()
        ref.set(fieldsWithFirestoreValues(fields)).await()
        ref.id
    }

    suspend fun deletePost(id: String) = withContext(Dispatchers.IO) {
        db.collection("posts").document(id).delete().await()
    }

    suspend fun toggleLike(postId: String, uid: String, like: Boolean) = withContext(Dispatchers.IO) {
        val ref = db.collection("posts").document(postId)
        ref.update("likes", if (like) FieldValue.arrayUnion(uid) else FieldValue.arrayRemove(uid)).await()
    }

    suspend fun getUser(uid: String): AppUser? = withContext(Dispatchers.IO) {
        val snapshot = db.collection("users").document(uid).get().await()
        if (!snapshot.exists()) null else AppUser.fromDocument(snapshot)
    }

    suspend fun updateUser(uid: String, fields: Map<String, Any?>) = withContext(Dispatchers.IO) {
        db.collection("users").document(uid).set(fieldsWithFirestoreValues(fields), com.google.firebase.firestore.SetOptions.merge()).await()
    }

    suspend fun fetchOrCreateUser(uid: String, name: String?, image: String?): AppUser =
        withContext(Dispatchers.IO) {
            getUser(uid)?.let { return@withContext it }

            val username = name ?: "User"
            val fields = mapOf(
                "username" to username,
                "profilePic" to (image ?: ""),
                "userNumber" to 0L,
                "createdAt" to FieldValue.serverTimestamp(),
            )
            db.collection("users").document(uid).set(fields).await()
            AppUser(uid, username, image, 0)
        }

    private fun fieldsWithFirestoreValues(fields: Map<String, Any?>): Map<String, Any?> =
        fields.mapValues { (_, value) ->
            when (value) {
                is Instant -> com.google.firebase.Timestamp(value.epochSecond, value.nano)
                else -> value
            }
        }

    private fun Any?.asFirestoreMap(): Any? = when (this) {
        is Instant -> com.google.firebase.Timestamp(this.epochSecond, this.nano)
        is List<*> -> map { it.asFirestoreMap() }
        is Map<*, *> -> entries.associate { it.key.toString() to it.value.asFirestoreMap() }
        else -> this
    }

    private fun fieldsWithFirestoreValuesCompat(fields: Map<String, Any?>): Map<String, Any?> =
        fields.mapValues { (_, value) -> value.asFirestoreMap() }
}
