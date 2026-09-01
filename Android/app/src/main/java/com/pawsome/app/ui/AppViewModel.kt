package com.example.pawsome.ui

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
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
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestoreException
import com.google.firebase.firestore.ListenerRegistration
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

    private var userListener: ListenerRegistration? = null
    private var creatingUserUid: String? = null

    private val authStateListener = FirebaseAuth.AuthStateListener { auth ->
        busyGoogle = false
        busyTwitter = false
        handleAuthState(auth.currentUser)
    }

    init {
        // Firebase immediately invokes this listener with the current auth state,
        // so there is no separate currentUser fetch here. This prevents the same
        // users/{uid} document from being read twice on startup.
        firebaseAuth.addAuthStateListener(authStateListener)
    }

    private fun handleAuthState(current: FirebaseUser?) {
        userListener?.remove()
        userListener = null
        creatingUserUid = null

        if (current == null) {
            signedIn = false
            loading = false
            user = null
            posts = emptyList()
            return
        }

        signedIn = true
        loading = true
        error = null

        val currentUid = current.uid
        userListener = firestore.listenToUser(
            uid = currentUid,
            onUserChanged = { firestoreUser ->
                if (firestoreUser != null) {
                    // A profile update is delivered here without creating another
                    // one-shot read or another listener.
                    user = firestoreUser
                    loading = false
                    loadFeed()
                    return@listenToUser
                }

                // The document does not exist yet. Only one creation attempt is
                // allowed for this UID; the snapshot listener will receive the new
                // document once the transaction commits.
                if (creatingUserUid == currentUid) return@listenToUser
                creatingUserUid = currentUid

                viewModelScope.launch {
                    try {
                        val created = firestore.fetchOrCreateUser(
                            currentUid,
                            current.displayName,
                            current.photoUrl?.toString(),
                            loginMethod(current),
                        )
                        user = created
                        loading = false
                        loadFeed()
                    } catch (e: Exception) {
                        loading = false
                        error = firestoreErrorMessage(e)
                    } finally {
                        if (creatingUserUid == currentUid) {
                            creatingUserUid = null
                        }
                    }
                }
            },
            onError = { exception ->
                // A Firestore listener stops after a terminal error such as
                // PERMISSION_DENIED, so don't keep retrying the same read in a loop.
                loading = false
                error = firestoreErrorMessage(exception)
            },
        )
    }

    private fun firestoreErrorMessage(error: Exception): String {
        return if (error is FirebaseFirestoreException &&
            error.code == FirebaseFirestoreException.Code.PERMISSION_DENIED
        ) {
            "Firestore denied access to users/${uid ?: "<uid>"}. Check the Firestore rule for users/{uid}: the signed-in user's auth UID must match the document UID."
        } else {
            error.message ?: "Firestore operation failed"
        }
    }

    fun signIn(context: android.content.Context) {
        busyGoogle = true
        error = null
        try {
            google.startSignIn(context)
        } catch (e: Exception) {
            busyGoogle = false
            error = e.message ?: "Sign-in failed"
        }
    }

    fun handleGoogleSignInResult(resultCode: Int, data: Intent?) = viewModelScope.launch {
        if (resultCode != Activity.RESULT_OK) {
            busyGoogle = false
            return@launch
        }

        try {
            val account = google.getAccountFromResult(data)
            val idToken = account.idToken
                ?: throw IllegalStateException("Google did not return an ID token.")
            val credential = GoogleAuthProvider.getCredential(idToken, null)
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
        userListener?.remove()
        userListener = null
        creatingUserUid = null
        firebaseAuth.signOut()
        signedIn = false
        user = null
        posts = emptyList()
        loading = false
    }

    fun loadFeed() = viewModelScope.launch {
        if (firebaseAuth.currentUser == null) return@launch

        try {
            posts = firestore.getPosts()
        } catch (e: Exception) {
            error = firestoreErrorMessage(e)
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

    private fun loginMethod(user: com.google.firebase.auth.FirebaseUser): String {
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

    override fun onCleared() {
        userListener?.remove()
        userListener = null
        firebaseAuth.removeAuthStateListener(authStateListener)
        super.onCleared()
    }
}
