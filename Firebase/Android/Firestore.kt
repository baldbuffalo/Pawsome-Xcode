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

data class ChatConversation(
    val id: String,
    val otherUid: String,
    val otherName: String,
    val lastMessage: String,
    val updatedAtMillis: Long,
)

data class ChatMessage(
    val id: String,
    val senderUid: String,
    val text: String,
    val timestampMillis: Long,
)

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

    suspend fun createPostForUser(uid: String, fields: Map<String, Any?>): String = withContext(Dispatchers.IO) {
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

    suspend fun deletePost(id: String) = withContext(Dispatchers.IO) { db.collection("posts").document(id).delete().await() }

    suspend fun toggleLike(postId: String, uid: String, like: Boolean) = withContext(Dispatchers.IO) {
        val ref = db.collection("posts").document(postId)
        ref.update("likes", if (like) FieldValue.arrayUnion(uid) else FieldValue.arrayRemove(uid)).await()
    }

    suspend fun getUser(uid: String): AppUser? = withContext(Dispatchers.IO) {
        db.collection("users").document(uid).get().await().takeIf { it.exists() }?.let(AppUser::fromDocument)
    }

    suspend fun findUserByUserNumber(userNumber: Int): AppUser? = withContext(Dispatchers.IO) {
        db.collection("users").whereEqualTo("UserID", userNumber.toLong()).limit(1).get().await().documents.firstOrNull()?.let(AppUser::fromDocument)
    }

    fun observeUser(uid: String, onUserChanged: (AppUser?) -> Unit, onError: (Exception) -> Unit): ListenerRegistration {
        return db.collection("users").document(uid).addSnapshotListener { snapshot, error ->
            if (error != null) { onError(error); return@addSnapshotListener }
            onUserChanged(snapshot?.takeIf { it.exists() }?.let(AppUser::fromDocument))
        }
    }

    suspend fun updateUser(uid: String, fields: Map<String, Any?>) = withContext(Dispatchers.IO) {
        db.collection("users").document(uid).set(prepareFields(fields), SetOptions.merge()).await()
    }

    suspend fun getConversations(uid: String): List<ChatConversation> = withContext(Dispatchers.IO) {
        db.collection("chats").whereArrayContains("participants", uid).get().await().documents.mapNotNull { d ->
            val participants = d.get("participants") as? List<*> ?: return@mapNotNull null
            val otherUid = participants.filterIsInstance<String>().firstOrNull { it != uid } ?: return@mapNotNull null
            ChatConversation(
                id = d.id,
                otherUid = otherUid,
                otherName = d.getString("${otherUid}_name") ?: "Pawsome user",
                lastMessage = d.getString("lastMessage") ?: "",
                updatedAtMillis = d.getTimestamp("updatedAt")?.toDate()?.time ?: 0L,
            )
        }.sortedByDescending { it.updatedAtMillis }
    }

    suspend fun createOrGetConversation(uid: String, otherUid: String, otherName: String, myName: String): String = withContext(Dispatchers.IO) {
        if (uid == otherUid) throw FirestoreException("You cannot chat with yourself")
        val id = listOf(uid, otherUid).sorted().joinToString("_")
        val ref = db.collection("chats").document(id)
        val existing = ref.get().await()
        if (!existing.exists()) {
            ref.set(mapOf(
                "participants" to listOf(uid, otherUid),
                "${uid}_name" to myName,
                "${otherUid}_name" to otherName,
                "lastMessage" to "",
                "updatedAt" to FieldValue.serverTimestamp(),
            )).await()
        }
        id
    }

    fun observeMessages(chatId: String, onChanged: (List<ChatMessage>) -> Unit, onError: (Exception) -> Unit): ListenerRegistration {
        return db.collection("chats").document(chatId).collection("messages")
            .orderBy("timestamp", Query.Direction.ASCENDING)
            .addSnapshotListener { snapshot, error ->
                if (error != null) { onError(error); return@addSnapshotListener }
                onChanged(snapshot?.documents?.map { d ->
                    ChatMessage(
                        id = d.id,
                        senderUid = d.getString("senderUid") ?: "",
                        text = d.getString("text") ?: "",
                        timestampMillis = d.getTimestamp("timestamp")?.toDate()?.time ?: 0L,
                    )
                } ?: emptyList())
            }
    }

    suspend fun sendMessage(chatId: String, senderUid: String, text: String) = withContext(Dispatchers.IO) {
        val chat = db.collection("chats").document(chatId)
        val message = chat.collection("messages").document()
        db.runTransaction { transaction ->
            transaction.set(message, mapOf(
                "senderUid" to senderUid,
                "text" to text,
                "timestamp" to FieldValue.serverTimestamp(),
            ))
            transaction.set(chat, mapOf(
                "lastMessage" to text,
                "updatedAt" to FieldValue.serverTimestamp(),
            ), SetOptions.merge())
        }.await()
    }

    suspend fun createPossibleMatchNotification(foundPostId: String, lostPost: Post, finderUid: String) = withContext(Dispatchers.IO) {
        val owner = findUserByUserNumber(lostPost.userId) ?: throw FirestoreException("Could not find the Lost Cat owner")
        db.collection("notifications").document().set(mapOf(
            "recipientUid" to owner.uid,
            "senderUid" to finderUid,
            "type" to "possible_cat_match",
            "foundPostId" to foundPostId,
            "lostPostId" to lostPost.id,
            "catName" to lostPost.catName,
            "createdAt" to FieldValue.serverTimestamp(),
            "read" to false,
        )).await()
    }

    suspend fun fetchOrCreateUser(uid: String, name: String?, image: String?, loginMethod: String = "Unknown"): AppUser = withContext(Dispatchers.IO) {
        getUser(uid)?.let { return@withContext it }
        val username = name ?: "User"
        val userRef = db.collection("users").document(uid)
        val counterRef = db.collection("counter").document("users")
        val userNumber = db.runTransaction { transaction ->
            val existingUser = transaction.get(userRef)
            if (existingUser.exists()) return@runTransaction existingUser.getLong("UserID") ?: 0L
            val counterSnapshot = transaction.get(counterRef)
            val nextUserNumber = (counterSnapshot.getLong("lastUserID") ?: 0L) + 1L
            transaction.set(counterRef, mapOf("lastUserID" to nextUserNumber), SetOptions.merge())
            transaction.set(userRef, mapOf(
                "Username" to username,
                "ProfilePic" to (image ?: ""),
                "UserID" to nextUserNumber,
                "LoginMethod" to loginMethod,
                "JoinedOn" to FieldValue.serverTimestamp(),
            ))
            nextUserNumber
        }.await()
        AppUser(uid, username, image, userNumber.toInt(), loginMethod, System.currentTimeMillis())
    }

    private fun prepareFields(fields: Map<String, Any?>): Map<String, Any?> = fields.mapValues { (_, value) -> toFirestoreValue(value) }
    private fun toFirestoreValue(value: Any?): Any? = when (value) {
        is Instant -> Timestamp(value.epochSecond, value.nano)
        is DocumentReference -> value
        is List<*> -> value.map(::toFirestoreValue)
        is Map<*, *> -> value.entries.associate { (key, nested) -> key.toString() to toFirestoreValue(nested) }
        else -> value
    }
}
