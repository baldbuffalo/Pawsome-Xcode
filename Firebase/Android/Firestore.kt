package com.example.pawsome.firebase

import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.tasks.await

/** Android-native Firestore adapter. */
class Firestore {
    private val db = FirebaseFirestore.getInstance()

    suspend fun getPosts(limit: Int = 50): List<Post> =
        db.collection("posts")
            .orderBy("PostedAt", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .get().await().documents.mapNotNull { Post.fromDocument(it) }

    suspend fun createPost(fields: Map<String, Any?>): String {
        val ref = db.collection("posts").document()
        ref.set(fields).await()
        return ref.id
    }

    suspend fun createPostForUser(uid: String, fields: Map<String, Any?>): String {
        val user = getUser(uid) ?: throw FirestoreException("User profile does not exist")
        val postFields = fields.toMutableMap().apply {
            put("UserId", user.userNumber)
            put("Username", user.username)
            put("ProfilePic", user.profilePic ?: "")
            put("PostedAt", FieldValue.serverTimestamp())
        }
        val ref = db.collection("posts").document()
        ref.set(postFields).await()
        return ref.id
    }

    suspend fun deletePost(id: String) { db.collection("posts").document(id).delete().await() }

    suspend fun toggleLike(postId: String, uid: String, like: Boolean) {
        val value = if (like) FieldValue.arrayUnion(uid) else FieldValue.arrayRemove(uid)
        db.collection("posts").document(postId).update("likes", value).await()
    }

    suspend fun getUser(uid: String): AppUser? {
        val snapshot = db.collection("users").document(uid).get().await()
        return if (snapshot.exists()) AppUser.fromDocument(snapshot) else null
    }

    suspend fun updateUser(uid: String, fields: Map<String, Any?>) {
        db.collection("users").document(uid).set(fields, SetOptions.merge()).await()
    }

    suspend fun fetchOrCreateUser(uid: String, name: String?, image: String?): AppUser {
        getUser(uid)?.let { return it }
        val username = name ?: "User"
        val userRef = db.collection("users").document(uid)
        val counterRef = db.collection("counter").document("users")

        val userNumber = db.runTransaction { transaction ->
            val counterSnapshot = transaction.get(counterRef)
            val nextUserNumber = (counterSnapshot.getLong("lastUserNumber") ?: 0L) + 1L
            transaction.set(counterRef, mapOf("lastUserNumber" to nextUserNumber), SetOptions.merge())
            transaction.set(userRef, mapOf(
                "username" to username,
                "profilePic" to (image ?: ""),
                "userNumber" to nextUserNumber,
                "joinedOn" to FieldValue.serverTimestamp(),
            ))
            nextUserNumber
        }.await()

        return AppUser(uid, username, image, userNumber.toInt())
    }
}
