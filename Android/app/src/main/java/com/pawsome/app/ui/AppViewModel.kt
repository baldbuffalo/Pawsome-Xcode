package com.example.pawsome.ui

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.pawsome.auth.GoogleAuth
import com.example.pawsome.model.AppUser
import com.example.pawsome.model.Post
import com.example.pawsome.net.ChatConversation
import com.example.pawsome.net.ChatMessage
import com.example.pawsome.net.Firestore
import com.example.pawsome.net.GitHubUploader
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.OAuthProvider
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.ListenerRegistration
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.InputStream

class AppViewModel(private val app: Application) : AndroidViewModel(app) {
    private val firebaseAuth = FirebaseAuth.getInstance()
    private val firestore = Firestore()
    private val github = GitHubUploader()
    private val google = GoogleAuth()
    private val prefs = app.getSharedPreferences("pawsome", Context.MODE_PRIVATE)

    var loading by mutableStateOf(true); private set
    var signedIn by mutableStateOf(false); private set
    var isAdmin by mutableStateOf(false); private set
    var busyGoogle by mutableStateOf(false); private set
    var busyTwitter by mutableStateOf(false); private set
    var busyPost by mutableStateOf(false); private set
    var error by mutableStateOf<String?>(null)
    var user by mutableStateOf<AppUser?>(null); private set
    var posts by mutableStateOf<List<Post>>(emptyList()); private set
    var conversations by mutableStateOf<List<ChatConversation>>(emptyList()); private set
    var chatLoading by mutableStateOf(false); private set
    var activeConversationId by mutableStateOf<String?>(null); private set
    var activeConversationName by mutableStateOf<String?>(null); private set
    var activeMessages by mutableStateOf<List<ChatMessage>>(emptyList()); private set
    var possibleMatches by mutableStateOf<List<Post>>(emptyList()); private set
    var matchLoading by mutableStateOf(false); private set
    var pendingFoundPostId by mutableStateOf<String?>(null); private set

    val isBusy: Boolean get() = busyGoogle || busyTwitter
    val uid: String? get() = firebaseAuth.currentUser?.uid

    private var observedUid: String? = null
    private var authStateReceived = false
    private var userListener: ListenerRegistration? = null
    private var messagesListener: ListenerRegistration? = null
    private var notificationListener: ListenerRegistration? = null

    private val authStateListener = FirebaseAuth.AuthStateListener { auth ->
        busyGoogle = false; busyTwitter = false; authStateReceived = true
        val current = auth.currentUser
        val currentUid = current?.uid
        if (currentUid == observedUid && observedUid != null) return@AuthStateListener
        userListener?.remove(); userListener = null
        messagesListener?.remove(); messagesListener = null
        notificationListener?.remove(); notificationListener = null
        observedUid = currentUid
        conversations = emptyList(); activeMessages = emptyList(); activeConversationId = null
        if (current == null) {
            signedIn = false; isAdmin = false; user = null; posts = emptyList(); loading = false; error = null; return@AuthStateListener
        }
        signedIn = false; loading = true; error = null
        viewModelScope.launch {
            try {
                val completed = withTimeoutOrNull(15_000L) {
                    val token = current.getIdToken(false).await()
                    isAdmin = token.claims["admin"] == true
                    val profile = firestore.fetchOrCreateUser(current.uid, current.displayName, current.photoUrl?.toString(), loginMethod(current))
                    userListener = firestore.observeUser(current.uid, { updated -> if (observedUid == current.uid) user = updated ?: profile }, { e -> if (observedUid == current.uid) error = e.message ?: "Could not listen to user profile" })
                    user = profile
                    posts = firestore.getPosts()
                    signedIn = true
                    loadConversations()
                    startChatNotificationListener()
                    true
                }
                if (completed == null && observedUid == current.uid) {
                    signedIn = false; isAdmin = false; user = null; posts = emptyList(); userListener?.remove(); userListener = null
                    error = "Could not connect to Firebase. Check your internet connection and try again."
                }
            } catch (e: Exception) {
                if (observedUid == current.uid) {
                    signedIn = false; isAdmin = false; user = null; posts = emptyList(); userListener?.remove(); userListener = null
                    error = e.message ?: "Could not connect to Firebase. Check your connection and try again."
                }
            } finally { if (observedUid == current.uid) loading = false }
        }
    }

    init {
        firebaseAuth.addAuthStateListener(authStateListener)
        viewModelScope.launch {
            delay(15_000L)
            if (loading && !authStateReceived) {
                loading = false; signedIn = false; isAdmin = false; user = null; posts = emptyList()
                error = "Firebase Auth is unavailable. Check your internet connection and try again."
            }
        }
    }

    override fun onCleared() {
        userListener?.remove(); messagesListener?.remove(); notificationListener?.remove()
        firebaseAuth.removeAuthStateListener(authStateListener)
        super.onCleared()
    }

    fun signIn(context: android.content.Context) {
        busyGoogle = true; error = null
        try { google.startSignIn(context) } catch (e: Exception) { busyGoogle = false; error = e.message ?: "Sign-in failed" }
    }

    fun handleGoogleSignInResult(resultCode: Int, data: Intent?) = viewModelScope.launch {
        if (resultCode != Activity.RESULT_OK) { busyGoogle = false; return@launch }
        try {
            val account = google.getAccountFromResult(data)
            val idToken = account.idToken ?: throw IllegalStateException("Google did not return an ID token.")
            firebaseAuth.signInWithCredential(GoogleAuthProvider.getCredential(idToken, null)).await()
        } catch (e: Exception) { error = e.message ?: "Sign-in failed" } finally { busyGoogle = false }
    }

    fun signInTwitter(context: android.content.Context) {
        busyTwitter = true; error = null
        viewModelScope.launch {
            try {
                val provider = OAuthProvider.newBuilder("twitter.com", firebaseAuth).build()
                firebaseAuth.startActivityForSignInWithProvider(context as android.app.Activity, provider).await()
            } catch (e: Exception) { error = e.message ?: "Sign-in failed"; busyTwitter = false }
        }
    }

    fun signOut() { firebaseAuth.signOut() }
    fun loadFeed() = viewModelScope.launch { try { posts = firestore.getPosts() } catch (e: Exception) { error = e.message } }
    fun toggleLike(p: Post) { val u = uid ?: return; viewModelScope.launch { try { firestore.toggleLike(p.id, u, !p.isLikedBy(u)); loadFeed() } catch (e: Exception) { error = e.message } } }

    fun deletePost(p: Post) = viewModelScope.launch {
        try { p.imageFileName?.let { if (github.hasToken) github.deleteFile("postImages/$it") }; firestore.deletePost(p.id); loadFeed() }
        catch (e: Exception) { error = e.message }
    }

    fun createPost(uri: Uri, name: String, age: String, desc: String, location: String, status: com.example.pawsome.model.PostStatus, onDone: () -> Unit) = viewModelScope.launch {
        busyPost = true; error = null
        var cachedFile: File? = null
        try {
            val u = user ?: throw Exception("Not signed in")
            if (!github.hasToken) throw Exception("No image-upload token in this build.")
            cachedFile = cachePickedImage(uri)
            val jpeg = withContext(Dispatchers.IO) { encodeJpeg(Uri.fromFile(cachedFile)) }
            val fileName = "${u.uid}_${System.currentTimeMillis() / 1000}.jpg"
            val url = github.uploadImage(jpeg, fileName, "postImages")
            val createdId = firestore.createPostForUser(u.uid, mapOf(
                "CatName" to name.trim(), "CatAge" to age.trim(), "description" to desc.trim(), "location" to location.trim(),
                "imageURL" to url, "likes" to emptyList<String>(), "status" to status.name,
            ))
            loadFeed()
            if (status == com.example.pawsome.model.PostStatus.FOUND) {
                pendingFoundPostId = createdId
                findPossibleMatches(name, desc, location)
            } else {
                pendingFoundPostId = null; possibleMatches = emptyList()
            }
            onDone()
        } catch (e: Exception) { error = e.message }
        finally { cachedFile?.delete(); busyPost = false }
    }

    fun checkFoundPostForMatches(post: Post) {
        if (post.status != com.example.pawsome.model.PostStatus.FOUND || post.userId.toString() != uid) return
        pendingFoundPostId = post.id
        findPossibleMatches(post.catName, post.description, post.location)
    }

    fun findPossibleMatches(catName: String, description: String, location: String) = viewModelScope.launch {
        matchLoading = true
        val lost = posts.filter { it.status == com.example.pawsome.model.PostStatus.LOST }
        val queryWords = ("$catName $description $location").lowercase().split(Regex("[^a-z0-9]+" )).filter { it.length >= 3 }.toSet()
        possibleMatches = lost.map { post ->
            val haystack = "${post.catName} ${post.description} ${post.location}".lowercase()
            val score = queryWords.count { haystack.contains(it) } + if (location.isNotBlank() && post.location.equals(location.trim(), true)) 5 else 0
            post to score
        }.filter { it.second > 0 }.sortedByDescending { it.second }.take(10).map { it.first }
        matchLoading = false
    }

    fun notifyPossibleMatch(foundPostId: String, lostPost: Post) = viewModelScope.launch {
        try {
            val u = uid ?: throw Exception("Not signed in")
            firestore.createPossibleMatchNotification(foundPostId, lostPost, u)
            error = "The owner of ${lostPost.catName} has been notified in their chat."
        } catch (e: Exception) { error = e.message }
    }

    fun dismissMatches() { pendingFoundPostId = null; possibleMatches = emptyList() }

    fun loadConversations() = viewModelScope.launch {
        val u = uid ?: return@launch
        chatLoading = true
        try { conversations = firestore.getConversations(u) } catch (e: Exception) { error = e.message } finally { chatLoading = false }
    }

    fun startChatWithUser(otherUid: String, otherName: String) = viewModelScope.launch {
        try {
            val u = uid ?: throw Exception("Not signed in")
            val id = firestore.createOrGetConversation(u, otherUid, otherName, user?.username ?: "User")
            openConversation(id, otherUid, otherName)
            loadConversations()
        } catch (e: Exception) { error = e.message }
    }

    fun openConversation(id: String, otherUid: String, otherName: String) {
        messagesListener?.remove()
        activeConversationId = id; activeConversationName = otherName; activeMessages = emptyList()
        messagesListener = firestore.observeMessages(id, uid ?: return, { activeMessages = it }, { e -> error = e.message })
    }

    fun closeConversation() { messagesListener?.remove(); messagesListener = null; activeConversationId = null; activeConversationName = null; activeMessages = emptyList(); loadConversations() }

    fun startChatNotificationListener() {
        notificationListener?.remove()
        val u = uid ?: return
        notificationListener = firestore.observeChatNotifications(u, { text, chatId, otherUid, otherName ->
            showChatNotification(text, chatId)
        }, { e -> error = e.message })
    }

    private fun showChatNotification(text: String, chatId: String) {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(app, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val notification = NotificationCompat.Builder(app, "pawsome_chat")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("Pawsome chat")
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        NotificationManagerCompat.from(app).notify(chatId.hashCode() and 0x7fffffff, notification)
    }

    fun sendMessage(text: String) = viewModelScope.launch {
        try { val id = activeConversationId ?: return@launch; val u = uid ?: return@launch; firestore.sendMessage(id, u, text) }
        catch (e: Exception) { error = e.message }
    }

    private suspend fun cachePickedImage(uri: Uri): File = withContext(Dispatchers.IO) {
        val file = File.createTempFile("pawsome_image_", ".tmp", app.cacheDir)
        try {
            openUriInputStream(uri).use { input -> if (input == null) throw Exception("Could not read the selected image"); file.outputStream().use { output -> input.copyTo(output) } }
            if (file.length() == 0L) throw Exception("The selected image is empty")
            file
        } catch (e: Exception) { file.delete(); throw e }
    }

    private fun openUriInputStream(uri: Uri): InputStream? = when (uri.scheme) {
        "content" -> app.contentResolver.openInputStream(uri)
        "file" -> uri.path?.let(::FileInputStream)
        else -> throw Exception("Unsupported image URI: ${uri.scheme ?: "unknown"}")
    }

    private fun loginMethod(user: FirebaseUser): String {
        val providerId = user.providerData.firstOrNull { it.providerId != "firebase" }?.providerId
        return when (providerId) { "google.com" -> "Google"; "twitter.com" -> "Twitter"; "password" -> "Email/Password"; null -> "Unknown"; else -> providerId.substringBefore('.').replaceFirstChar { it.uppercase() } }
    }

    private fun encodeJpeg(uri: Uri, maxDim: Int = 1200): ByteArray {
        val src = openUriInputStream(uri).use { BitmapFactory.decodeStream(it) } ?: throw Exception("Could not read image")
        val scale = minOf(1f, maxDim.toFloat() / maxOf(src.width, src.height))
        val bmp = if (scale < 1f) Bitmap.createScaledBitmap(src, (src.width * scale).toInt(), (src.height * scale).toInt(), true) else src
        return ByteArrayOutputStream().apply { bmp.compress(Bitmap.CompressFormat.JPEG, 80, this) }.toByteArray()
    }
}
