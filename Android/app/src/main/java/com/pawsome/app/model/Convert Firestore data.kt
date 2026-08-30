package com.example.pawsome.model

import com.google.firebase.firestore.DocumentSnapshot

enum class PostStatus(val displayName: String, val emoji: String) {
    LOST("Lost", "🆘"),
    FOUND("Found", "🎉"),
    REUNITED("Reunited", "🏠");

    companion object {
        fun fromString(s: String?): PostStatus = entries.find { it.name.equals(s, true) } ?: LOST
    }
}

data class Post(
    val id: String,
    val catName: String,
    val description: String,
    val age: String,
    val imageUrl: String,
    val userId: Int,
    val username: String,
    val profilePic: String,
    val postedAtMillis: Long,
    val likes: List<String>,
    val commentCount: Int,
    val status: PostStatus = PostStatus.LOST,
    val location: String = "",
) {
    val likeCount get() = likes.size
    val timeAgo get() = timeAgoFrom(postedAtMillis)
    fun isLikedBy(uid: String?) = uid != null && likes.contains(uid)
    val imageFileName: String? get() = imageUrl.substringAfterLast('/', "").substringBefore('?').ifBlank { null }

    companion object {
        fun fromDocument(document: DocumentSnapshot): Post? {
            val catName = document.getString("CatName") ?: return null
            val imageUrl = document.getString("imageURL") ?: return null
            val userId = (document.getLong("UserID") ?: return null).toInt()
            val likes = document.get("likes")
                .let { value -> (value as? List<*>)?.filterIsInstance<String>() ?: emptyList() }
            return Post(
                id = document.id,
                catName = catName,
                description = document.getString("description") ?: "",
                age = document.getString("CatAge") ?: "",
                imageUrl = imageUrl,
                userId = userId,
                username = document.getString("Username") ?: "User",
                profilePic = document.getString("ProfilePic") ?: "",
                postedAtMillis = document.getTimestamp("PostedAt")?.toDate()?.time ?: 0L,
                likes = likes,
                commentCount = (document.getLong("commentCount") ?: 0L).toInt(),
                status = PostStatus.fromString(document.getString("status")),
                location = document.getString("location") ?: "",
            )
        }
    }
}

data class AppUser(
    val uid: String,
    var username: String,
    var profilePic: String?,
    val userNumber: Int,
) {
    companion object {
        fun fromDocument(document: DocumentSnapshot) = AppUser(
            uid = document.id,
            username = document.getString("Usename") ?: "User",
            profilePic = document.getString("ProfilePic"),
            userNumber = (document.getLong("UserID") ?: 0L).toInt(),
        )
    }
}

fun timeAgoFrom(millis: Long): String {
    val s = (System.currentTimeMillis() - millis).coerceAtLeast(0) / 1000
    return when {
        s >= 31_536_000 -> "${s / 31_536_000}y ago"
        s >= 2_592_000 -> "${s / 2_592_000}mo ago"
        s >= 604_800 -> "${s / 604_800}w ago"
        s >= 86_400 -> "${s / 86_400}d ago"
        s >= 3_600 -> "${s / 3_600}h ago"
        s >= 60 -> "${s / 60}m ago"
        s >= 1 -> "${s}s ago"
        else -> "just now"
    }
}
