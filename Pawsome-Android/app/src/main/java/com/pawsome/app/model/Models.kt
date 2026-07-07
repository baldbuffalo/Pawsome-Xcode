package com.example.pawsome.model

import com.example.pawsome.net.long
import com.example.pawsome.net.millis
import com.example.pawsome.net.str
import com.example.pawsome.net.strList

data class Post(
    val id: String,
    val catName: String,
    val description: String,
    val age: String,
    val imageUrl: String,
    val ownerUid: String,
    val ownerUsername: String,
    val ownerProfilePic: String,
    val timestampMillis: Long,
    val likes: List<String>,
    val commentCount: Int,
) {
    val likeCount get() = likes.size
    val timeAgo get() = timeAgoFrom(timestampMillis)
    fun isLikedBy(uid: String?) = uid != null && likes.contains(uid)
    val imageFileName: String? get() = imageUrl.substringAfterLast('/', "").substringBefore('?').ifBlank { null }

    companion object {
        fun fromFields(id: String, d: Map<String, Any?>): Post? {
            val catName = d.str("catName") ?: return null
            val imageUrl = d.str("imageURL") ?: return null
            val ownerUid = d.str("ownerUID") ?: return null
            return Post(
                id, catName,
                d.str("description") ?: "", d.str("age") ?: "",
                imageUrl, ownerUid,
                d.str("ownerUsername") ?: "User", d.str("ownerProfilePic") ?: "",
                d.millis("timestamp"), d.strList("likes"), d.long("commentCount").toInt()
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
        fun fromFields(uid: String, d: Map<String, Any?>) = AppUser(
            uid, d.str("username") ?: "User", d.str("profilePic"), d.long("userNumber").toInt()
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
