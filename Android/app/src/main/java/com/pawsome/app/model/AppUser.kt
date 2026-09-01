package com.example.pawsome.model

import com.google.firebase.firestore.DocumentSnapshot

data class AppUser(
    val uid: String,
    var username: String,
    var profilePic: String?,
    val userNumber: Int,
    val loginMethod: String,
    val joinedOnMillis: Long,
) {
    companion object {
        fun fromDocument(document: DocumentSnapshot) = AppUser(
            uid = document.id,
            // Read both spellings so existing profiles created by older builds
            // continue to work after the field is corrected to "Username".
            username = document.getString("Username")
                ?: document.getString("Usename")
                ?: "User",
            profilePic = document.getString("ProfilePic"),
            userNumber = (document.getLong("UserID") ?: 0L).toInt(),
            loginMethod = document.getString("LoginMethod") ?: "Unknown",
            joinedOnMillis = document.getTimestamp("JoinedOn")?.toDate()?.time ?: 0L,
        )
    }
}
