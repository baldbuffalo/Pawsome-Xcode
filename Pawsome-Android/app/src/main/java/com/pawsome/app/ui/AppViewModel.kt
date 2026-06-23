package com.pawsome.app.ui

import android.app.Application
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.pawsome.app.auth.GoogleAuth
import com.pawsome.app.model.AppUser
import com.pawsome.app.model.Post
import com.pawsome.app.net.FirebaseAuth
import com.pawsome.app.net.Firestore
import com.pawsome.app.net.GitHubUploader
import com.pawsome.app.net.Session
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.time.Instant

class AppViewModel(app: Application) : AndroidViewModel(app) {

    private val auth = FirebaseAuth()
    private val firestore = Firestore(auth)
    private val github = GitHubUploader()
    private val google = GoogleAuth()
    private val prefs = app.getSharedPreferences("pawsome", Context.MODE_PRIVATE)

    var loading by mutableStateOf(true); private set
    var signedIn by mutableStateOf(false); private set
    var busy by mutableStateOf(false); private set
    var error by mutableStateOf<String?>(null)
    var user by mutableStateOf<AppUser?>(null); private set
    var posts by mutableStateOf<List<Post>>(emptyList()); private set

    val uid get() = auth.current?.uid

    init { viewModelScope.launch { tryRestore() } }

    private suspend fun tryRestore() {
        val rt = prefs.getString("rt", null)
        if (rt != null) {
            val s = auth.restore(rt)
            if (s != null) { loadUser(s); signedIn = true; loadFeed() }
            else prefs.edit().remove("rt").apply()
        }
        loading = false
    }

    fun signIn(context: android.content.Context) = viewModelScope.launch {
        busy = true; error = null
        try {
            val idToken = google.signIn(context)
            val s = auth.signInWithGoogle(idToken)
            prefs.edit().putString("rt", s.refreshToken).apply()
            loadUser(s); signedIn = true; loadFeed()
        } catch (e: Exception) {
            error = e.message ?: "Sign-in failed"
        } finally { busy = false }
    }

    private suspend fun loadUser(s: Session) {
        user = firestore.fetchOrCreateUser(s.uid, s.displayName, s.photoUrl)
    }

    fun signOut() {
        auth.signOut(); prefs.edit().remove("rt").apply()
        signedIn = false; user = null; posts = emptyList()
    }

    fun loadFeed() = viewModelScope.launch {
        try { posts = firestore.getPosts() } catch (e: Exception) { error = e.message }
    }

    fun toggleLike(p: Post) {
        val u = uid ?: return
        viewModelScope.launch {
            try { firestore.toggleLike(p.id, u, !p.isLikedBy(u)); loadFeed() }
            catch (e: Exception) { error = e.message }
        }
    }

    fun deletePost(p: Post) = viewModelScope.launch {
        try {
            p.imageFileName?.let { if (github.hasToken) github.deleteFile("postImages/$it") }
            firestore.deletePost(p.id); loadFeed()
        } catch (e: Exception) { error = e.message }
    }

    fun createPost(uri: Uri, name: String, age: String, desc: String, onDone: () -> Unit) =
        viewModelScope.launch {
            busy = true; error = null
            try {
                val u = user ?: throw Exception("Not signed in")
                if (!github.hasToken) throw Exception("No image-upload token in this build.")
                val jpeg = withContext(Dispatchers.IO) { encodeJpeg(uri) }
                val fileName = "${u.uid}_${System.currentTimeMillis() / 1000}.jpg"
                val url = github.uploadImage(jpeg, fileName, "postImages")
                firestore.createPost(
                    mapOf(
                        "catName" to name.trim(), "description" to desc.trim(), "age" to age.trim(),
                        "imageURL" to url, "ownerUID" to u.uid, "ownerUsername" to u.username,
                        "ownerProfilePic" to (u.profilePic ?: ""), "timestamp" to Instant.now(),
                        "likes" to emptyList<String>(), "commentCount" to 0L,
                    )
                )
                loadFeed(); onDone()
            } catch (e: Exception) { error = e.message } finally { busy = false }
        }

    private fun encodeJpeg(uri: Uri, maxDim: Int = 1200): ByteArray {
        val cr = getApplication<Application>().contentResolver
        val src = cr.openInputStream(uri).use { BitmapFactory.decodeStream(it) }
            ?: throw Exception("Could not read image")
        val scale = minOf(1f, maxDim.toFloat() / maxOf(src.width, src.height))
        val bmp = if (scale < 1f)
            Bitmap.createScaledBitmap(src, (src.width * scale).toInt(), (src.height * scale).toInt(), true)
        else src
        return ByteArrayOutputStream().apply { bmp.compress(Bitmap.CompressFormat.JPEG, 80, this) }.toByteArray()
    }
}
