package com.example.pawsome.ui

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
import com.example.pawsome.auth.GoogleAuth
import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.example.pawsome.net.Firestore
import com.example.pawsome.net.GitHubUploader
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.OAuthProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream

class AppViewModel(private val app: Application) : AndroidViewModel(app) {

    private val firebaseAuth = FirebaseAuth.getInstance()
    private val firestore = Firestore()
    private val github = GitHubUploader()
    private val google = GoogleAuth()
    private val prefs = app.getSharedPreferences("pawsome", Context.MODE_PRIVATE)

    var loading by mutableStateOf(true); private set
    var signedIn by mutableStateOf(false); private set
    var busyGoogle by mutableStateOf(false); private set
    var busyTwitter by mutableStateOf(false); private set
    var busyPost by mutableStateOf(false); private set
    var error by mutableStateOf<String?>(null)
    var user by mutableStateOf<AppUser?>(null); private set
    var posts by mutableStateOf<List<Post>>(emptyList()); private set

    val isBusy: Boolean get() = busyGoogle || busyTwitter

    val uid: String? get() = firebaseAuth.currentUser?.uid

    init {
        val currentUser = firebaseAuth.currentUser
        if (currentUser != null) {
            signedIn = true
            loading = false
            restoreSignedInUser(currentUser)
        } else {
            loading = false
        }

        firebaseAuth.addAuthStateListener { auth ->
            busyGoogle = false
            busyTwitter = false

            val current = auth.currentUser
            if (current != null) {
                restoreSignedInUser(current)
            } else {
                signedIn = false
                user = null
                posts = emptyList()
                loading = false
            }
        }
    }

    /**
     * Restores the Firebase session without allowing a failed token refresh or
     * Firestore request to escape from viewModelScope and crash MainActivity.
     * A stale/invalid Firebase session is cleared and the user is returned to
     * the login screen instead.
     */
    private fun restoreSignedInUser(current: FirebaseUser) = viewModelScope.launch {
        loading = true
        error = null
        try {
            // Force Firebase to validate/refresh the cached session before
            // making authenticated Firestore requests. BAD_AUTHENTICATION can
            // otherwise surface asynchronously and kill this coroutine.
            current.getIdToken(true).await()

            user = firestore.fetchOrCreateUser(
                current.uid,
                current.displayName,
                current.photoUrl?.toString(),
                loginMethod(current),
            )
            signedIn = true
            loadFeed()
        } catch (e: Exception) {
            // Do not let an authentication/Firestore failure escape the
            // lifecycle coroutine. Clear the broken session so the app can
            // recover normally through the login screen.
            firebaseAuth.signOut()
            signedIn = false
            user = null
            posts = emptyList()
            error = "Your sign-in session expired. Please sign in again."
        } finally {
            loading = false
        }
    }

    fun signIn(context: android.content.Context) = viewModelScope.launch {
        busyGoogle = true
        error = null
        try {
            val idToken = google.signIn(context)
            val credential =
                com.google.firebase.auth.GoogleAuthProvider.getCredential(idToken, null)
            firebaseAuth.signInWithCredential(credential).await()
        } catch (e: Exception) {
            error = e.message ?: "Sign-in failed"
        } finally {
            busyGoogle = false
        }
    }

    fun signInTwitter(context: android.content.Context) {
        busyTwitter = true
        error = null
        viewModelScope.launch {
            try {
                val provider = OAuthProvider.newBuilder("twitter.com", firebaseAuth).build()
                firebaseAuth
                    .startActivityForSignInWithProvider(
                        context as android.app.Activity,
                        provider,
                    )
                    .await()
            } catch (e: Exception) {
                error = e.message ?: "Sign-in failed"
                busyTwitter = false
            }
        }
    }

    fun signOut() {
        firebaseAuth.signOut()
        signedIn = false
        user = null
        posts = emptyList()
    }

    fun loadFeed() = viewModelScope.launch {
        try {
            posts = firestore.getPosts()
        } catch (e: Exception) {
            error = e.message
        }
    }

    fun toggleLike(p: Post) {
        val u = uid ?: return
        viewModelScope.launch {
            try {
                firestore.toggleLike(p.id, u, !p.isLikedBy(u))
                loadFeed()
            } catch (e: Exception) {
                error = e.message
            }
        }
    }

    fun deletePost(p: Post) = viewModelScope.launch {
        try {
            p.imageFileName?.let {
                if (github.hasToken) github.deleteFile("postImages/$it")
            }
            firestore.deletePost(p.id)
            loadFeed()
        } catch (e: Exception) {
            error = e.message
        }
    }

    fun createPost(
        uri: Uri,
        name: String,
        age: String,
        desc: String,
        location: String,
        status: com.example.pawsome.model.PostStatus,
        onDone: () -> Unit,
    ) = viewModelScope.launch {
        busyPost = true
        error = null

        try {
            val u = user ?: throw Exception("Not signed in")
            if (!github.hasToken) {
                throw Exception("No image-upload token in this build.")
            }

            val jpeg = withContext(Dispatchers.IO) { encodeJpeg(uri) }
            val fileName = "${u.uid}_${System.currentTimeMillis() / 1000}.jpg"
            val url = github.uploadImage(jpeg, fileName, "postImages")

            firestore.createPostForUser(
                u.uid,
                mapOf(
                    "CatName" to name.trim(),
                    "CatAge" to age.trim(),
                    "description" to desc.trim(),
                    "location" to location.trim(),
                    "imageURL" to url,
                    "likes" to emptyList<String>(),
                    "commentCount" to 0L,
                    "status" to status.name,
                ),
            )

            loadFeed()
            onDone()
        } catch (e: Exception) {
            error = e.message
        } finally {
            busyPost = false
        }
    }

    private fun loginMethod(user: FirebaseUser): String {
        val providerId = user.providerData
            .firstOrNull { it.providerId != "firebase" }
            ?.providerId

        return when (providerId) {
            "google.com" -> "Google"
            "twitter.com" -> "Twitter"
            "password" -> "Email/Password"
            null -> "Unknown"
            else -> providerId
                .substringBefore('.')
                .replaceFirstChar { it.uppercase() }
        }
    }

    private fun encodeJpeg(uri: Uri, maxDim: Int = 1200): ByteArray {
        val cr = getApplication<Application>().contentResolver
        val src = cr.openInputStream(uri).use { BitmapFactory.decodeStream(it) }
            ?: throw Exception("Could not read image")

        val scale = minOf(1f, maxDim.toFloat() / maxOf(src.width, src.height))
        val bmp = if (scale < 1f) {
            Bitmap.createScaledBitmap(
                src,
                (src.width * scale).toInt(),
                (src.height * scale).toInt(),
                true,
            )
        } else {
            src
        }

        return ByteArrayOutputStream().apply {
            bmp.compress(Bitmap.CompressFormat.JPEG, 80, this)
        }.toByteArray()
    }
}
