package com.example.pawsome.net

import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.google.firebase.Timestamp
import com.google.firebase.firestore.DocumentReference
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.ListenerRegistration
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.Query
import com.google.firebase.firestore.SetOptions
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.time.Instant

class FirestoreException(message: String) : Exception(message)

class Firestore {
    private val db = FirebaseFirestore.getInstance()

    suspend fun getPosts(limit: Int = 50): List<Post> = withContext(Dispatchers.IO) {
        db.collection("posts")
            .orderBy("PostedAt", Query.Direction.DESCENDING)
            .limit(limit.toLong())
            .get()
            .await()
            .documents
            .mapNotNull { Post.fromDocument(it) }
    }

    suspend fun createPost(fields: Map<String, Any?>): String = withContext(Dispatchers.IO) {
        val ref = db.collection("posts").document()
        ref.set(prepareFields(fields)).await()
        ref.id
    }

    suspend fun createPostForUser(uid: String, fields: Map<String, Any?>): String =
        withContext(Dispatchers.IO) {
            val user = getUser(uid) ?: throw FirestoreException("User profile does not exist")

            val postFields = fields.toMutableMap().apply {
                put("UserID", user.userNumber)
                put("Username", user.username)
                put("ProfilePic", user.profilePic ?: "")
                put("PostedAt", FieldValue.serverTimestamp())
            }

            val ref = db.collection("posts").document()
            ref.set(prepareFields(postFields)).await()
            ref.id
        }

    suspend fun deletePost(id: String) = withContext(Dispatchers.IO) {
        db.collection("posts").document(id).delete().await()
    }

    suspend fun toggleLike(postId: String, uid: String, like: Boolean) = withContext(Dispatchers.IO) {
        val ref = db.collection("posts").document(postId)
        val value = if (like) FieldValue.arrayUnion(uid) else FieldValue.arrayRemove(uid)
        ref.update("likes", value).await()
    }

    suspend fun getUser(uid: String): AppUser? = withContext(Dispatchers.IO) {
        val snapshot = db.collection("users").document(uid).get().await()
        snapshot.takeIf { it.exists() }?.let(AppUser::fromDocument)
    }

    /**
     * Keeps the in-memory user profile synchronized with users/{uid}.
     * The caller owns the returned registration and must remove it when the
     * authenticated user changes or the ViewModel is cleared.
     */
    fun observeUser(
        uid: String,
        onUserChanged: (AppUser?) -> Unit,
        onError: (Exception) -> Unit,
    ): ListenerRegistration {
        return db.collection("users").document(uid)
            .addSnapshotListener { snapshot, error ->
                if (error != null) {
                    onError(error)
                    return@addSnapshotListener
                }

                onUserChanged(
                    snapshot?.takeIf { it.exists() }?.let(AppUser::fromDocument)
                )
            }
    }

    suspend fun updateUser(uid: String, fields: Map<String, Any?>) = withContext(Dispatchers.IO) {
        db.collection("users").document(uid)
            .set(prepareFields(fields), SetOptions.merge())
            .await()
    }

    suspend fun fetchOrCreateUser(
        uid: String,
        name: String?,
        image: String?,
        loginMethod: String = "Unknown",
    ): AppUser = withContext(Dispatchers.IO) {
        getUser(uid)?.let { return@withContext it }

        val username = name ?: "User"
        val userRef = db.collection("users").document(uid)
        val counterRef = db.collection("counter").document("users")

        val userNumber = db.runTransaction { transaction ->
            // Re-check inside the transaction so two auth callbacks cannot
            // create two profiles for the same UID.
            val existingUser = transaction.get(userRef)
            if (existingUser.exists()) {
                return@runTransaction existingUser.getLong("UserID") ?: 0L
            }

            val counterSnapshot = transaction.get(counterRef)
            val nextUserNumber =
                (counterSnapshot.getLong("lastUserID") ?: 0L) + 1L

            transaction.set(
                counterRef,
                mapOf("lastUserID" to nextUserNumber),
                SetOptions.merge(),
            )

            transaction.set(
                userRef,
                mapOf(
                    "Username" to username,
                    "ProfilePic" to (image ?: ""),
                    "UserID" to nextUserNumber,
                    "LoginMethod" to loginMethod,
                    "JoinedOn" to FieldValue.serverTimestamp(),
                ),
            )

            nextUserNumber
        }.await()

        AppUser(
            uid = uid,
            username = username,
            profilePic = image,
            userNumber = userNumber.toInt(),
            loginMethod = loginMethod,
            joinedOnMillis = System.currentTimeMillis(),
        )
    }

    private fun prepareFields(fields: Map<String, Any?>): Map<String, Any?> =
        fields.mapValues { (_, value) -> toFirestoreValue(value) }

    private fun toFirestoreValue(value: Any?): Any? = when (value) {
        is Instant -> Timestamp(value.epochSecond, value.nano)
        is DocumentReference -> value
        is List<*> -> value.map(::toFirestoreValue)
        is Map<*, *> -> value.entries.associate { (key, nested) ->
            key.toString() to toFirestoreValue(nested)
        }
        else -> value
    }
}
