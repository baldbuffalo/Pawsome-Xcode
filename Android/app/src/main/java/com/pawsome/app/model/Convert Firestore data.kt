package com.example.pawsome.model

import com.google.firebase.firestore.DocumentSnapshot

enum class PostStatus(
    val displayName: String,
    val emoji: String
) {
    LOST("Lost", "🆘"),
    FOUND("Found", "🎉"),
    REUNITED("Reunited", "🏠");

    companion object {
        fun fromString(value: String?): PostStatus {
            return entries.firstOrNull {
                it.name.equals(value, ignoreCase = true)
            } ?: LOST
        }
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
    val location: String = ""
) {
    val likeCount: Int
        get() = likes.size

    val timeAgo: String
        get() = timeAgoFrom(postedAtMillis)

    fun isLikedBy(uid: String?): Boolean {
        return uid != null && likes.contains(uid)
    }

    val imageFileName: String?
        get() {
            return imageUrl
                .substringAfterLast('/', "")
                .substringBefore('?')
                .ifBlank { null }
        }

    companion object {
        fun fromDocument(document: DocumentSnapshot): Post? {
            val catName = document.getString("CatName")
            if (catName == null) {
                return null
            }

            val imageUrl = document.getString("imageURL")
            if (imageUrl == null) {
                return null
            }

            val userIdValue = document.getLong("UserID")
            if (userIdValue == null) {
                return null
            }

            val likesValue = document.get("likes")
            val likes = if (likesValue is List<*>) {
                likesValue.filterIsInstance<String>()
            } else {
                emptyList()
            }

            val postedAtMillis =
                document.getTimestamp("PostedAt")
                    ?.toDate()
                    ?.time
                    ?: 0L

            return Post(
                id = document.id,
                catName = catName,
                description = document.getString("description") ?: "",
                age = document.getString("CatAge") ?: "",
                imageUrl = imageUrl,
                userId = userIdValue.toInt(),
                username = document.getString("Username") ?: "User",
                profilePic = document.getString("ProfilePic") ?: "",
                postedAtMillis = postedAtMillis,
                likes = likes,
                commentCount =
                    (document.getLong("commentCount") ?: 0L).toInt(),
                status =
                    PostStatus.fromString(
                        document.getString("status")
                    ),
                location = document.getString("location") ?: ""
            )
        }
    }
}

fun timeAgoFrom(millis: Long): String {
    val seconds =
        (System.currentTimeMillis() - millis)
            .coerceAtLeast(0L) / 1000L

    return when {
        seconds >= 31_536_000L ->
            "${seconds / 31_536_000L}y ago"

        seconds >= 2_592_000L ->
            "${seconds / 2_592_000L}mo ago"

        seconds >= 604_800L ->
            "${seconds / 604_800L}w ago"

        seconds >= 86_400L ->
            "${seconds / 86_400L}d ago"

        seconds >= 3_600L ->
            "${seconds / 3_600L}h ago"

        seconds >= 60L ->
            "${seconds / 60L}m ago"

        seconds >= 1L ->
            "${seconds}s ago"

        else ->
            "just now"
    }
}
