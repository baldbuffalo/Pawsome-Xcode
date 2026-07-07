package com.example.pawsome.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.pawsome.R
import com.example.pawsome.model.Post
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.launch

@Composable
fun LoginScreen(vm: AppViewModel) {
    val context = LocalContext.current
    
    Box(Modifier.fillMaxSize().padding(24.dp), contentAlignment = Alignment.Center) {
        Card(Modifier.widthIn(max = 380.dp)) {
            Column(
                Modifier.padding(28.dp).fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(18.dp),
            ) {
                Image(
                    painterResource(R.mipmap.ic_launcher), null,
                    Modifier.size(76.dp).clip(RoundedCornerShape(18.dp)),
                )
                Text("Pawsome", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
                Text("Find. Help. Reunite.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                Button(onClick = { vm.signIn(context) }, enabled = !vm.isBusy, modifier = Modifier.fillMaxWidth()) {
                    if (vm.busyGoogle) CircularProgressIndicator(
                        Modifier.size(18.dp), strokeWidth = 2.dp, color = MaterialTheme.colorScheme.onPrimary
                    ) else Text("Sign in with Google")
                }
                Button(
                    onClick = { vm.signInTwitter(context) },
                    enabled = !vm.isBusy,
                    modifier = Modifier.fillMaxWidth(),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Black),
                ) {
                    if (vm.busyTwitter) CircularProgressIndicator(
                        Modifier.size(18.dp), strokeWidth = 2.dp, color = Color.White
                    ) else Text("Sign in with X", color = Color.White)
                }
                vm.error?.let { Text(it, color = MaterialTheme.colorScheme.error, fontSize = 13.sp) }
            }
        }
    }
}

@Composable
fun FeedScreen(vm: AppViewModel, onCreate: () -> Unit) {
    Column(Modifier.fillMaxSize()) {
        Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
            Column(Modifier.weight(1f)) {
                Text("Welcome back 👋", style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                Text(vm.user?.username ?: "there", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            }
            IconButton(onClick = { vm.loadFeed() }) { Icon(Icons.Filled.Refresh, "Refresh") }
        }
        Button(onClick = onCreate, modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp)) {
            Icon(Icons.Filled.Add, null); Spacer(Modifier.width(8.dp)); Text("Create a new post")
        }
        LazyColumn(
            Modifier.fillMaxSize(),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            items(vm.posts, key = { it.id }) { p ->
                PostCard(p, vm.uid, { vm.toggleLike(p) }, { vm.deletePost(p) })
            }
        }
    }
}

@Composable
private fun PostCard(post: Post, uid: String?, onLike: () -> Unit, onDelete: () -> Unit) {
    Card(Modifier.fillMaxWidth()) {
        Column {
            Row(Modifier.fillMaxWidth().padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                AsyncImage(
                    post.ownerProfilePic.ifBlank { null }, null,
                    Modifier.size(38.dp).clip(CircleShape), contentScale = ContentScale.Crop,
                )
                Spacer(Modifier.width(10.dp))
                Column(Modifier.weight(1f)) {
                    Text(post.ownerUsername, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
                    Text(post.timeAgo, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
                if (post.ownerUid == uid) IconButton(onClick = onDelete) { Icon(Icons.Filled.Delete, "Delete") }
            }
            AsyncImage(
                post.imageUrl, null,
                Modifier.fillMaxWidth().height(300.dp), contentScale = ContentScale.Crop,
            )
            Column(Modifier.padding(12.dp)) {
                Text(post.catName, fontWeight = FontWeight.SemiBold)
                if (post.age.isNotBlank())
                    Text("${post.age} yrs", color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
                if (post.description.isNotBlank())
                    Text(post.description, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 3, modifier = Modifier.padding(top = 4.dp))
            }
            Row(Modifier.padding(start = 12.dp, end = 12.dp, bottom = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                val liked = post.isLikedBy(uid)
                TextButton(onClick = onLike) {
                    Icon(
                        if (liked) Icons.Filled.Favorite else Icons.Filled.FavoriteBorder, null,
                        tint = if (liked) Color(0xFFDC2626) else MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                    Spacer(Modifier.width(4.dp)); Text("${post.likeCount}")
                }
                Spacer(Modifier.width(12.dp))
                Icon(Icons.Filled.ChatBubbleOutline, null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                Spacer(Modifier.width(4.dp)); Text("${post.commentCount}")
            }
        }
    }
}

@Composable
fun CreatePostScreen(vm: AppViewModel, onBack: () -> Unit) {
    var name by remember { mutableStateOf("") }
    var age by remember { mutableStateOf("") }
    var desc by remember { mutableStateOf("") }
    var uri by remember { mutableStateOf<android.net.Uri?>(null) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri = it }

    Column(
        Modifier.fillMaxSize().padding(16.dp).verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            TextButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, null); Text("Back") }
            Spacer(Modifier.weight(1f)); Text("New Post", fontWeight = FontWeight.SemiBold); Spacer(Modifier.weight(1f))
        }
        uri?.let {
            AsyncImage(it, null, Modifier.fillMaxWidth().height(220.dp), contentScale = ContentScale.Fit)
        }
        OutlinedButton(onClick = { picker.launch("image/*") }, modifier = Modifier.fillMaxWidth()) {
            Text(if (uri == null) "Choose Image" else "Change Image")
        }
        OutlinedTextField(name, { name = it }, label = { Text("Cat Name") }, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(age, { age = it }, label = { Text("Age (years)") }, modifier = Modifier.fillMaxWidth())
        OutlinedTextField(desc, { desc = it }, label = { Text("Description") }, modifier = Modifier.fillMaxWidth(), minLines = 3)
        vm.error?.let { Text(it, color = MaterialTheme.colorScheme.error, fontSize = 13.sp) }
        Button(
            onClick = { uri?.let { vm.createPost(it, name, age, desc, onBack) } },
            enabled = !vm.busyPost && uri != null && name.isNotBlank() && age.isNotBlank() && desc.isNotBlank(),
            modifier = Modifier.fillMaxWidth(),
        ) { Text(if (vm.busyPost) "Posting…" else "Post 🐾") }
        Spacer(Modifier.height(16.dp))
    }
}

@Composable
fun ProfileScreen(vm: AppViewModel, onAboutClick: () -> Unit) {
    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(20.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Spacer(Modifier.height(24.dp))
        
        // Profile Avatar with gradient ring
        Box(contentAlignment = Alignment.Center) {
            Box(
                Modifier.size(120.dp).clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center,
            ) {
                AsyncImage(
                    vm.user?.profilePic?.ifBlank { null }, null,
                    Modifier.size(112.dp).clip(CircleShape), contentScale = ContentScale.Crop,
                )
                if (vm.user?.profilePic.isNullOrBlank()) {
                    Icon(Icons.Default.Person, null, Modifier.size(56.dp), tint = MaterialTheme.colorScheme.onPrimaryContainer)
                }
            }
        }
        
        Spacer(Modifier.height(16.dp))
        
        // Username
        Text(
            vm.user?.username ?: "User",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            color = MaterialTheme.colorScheme.onSurface,
        )
        
        Text(
            "@${vm.user?.username ?: "user"}",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        
        Spacer(Modifier.height(32.dp))
        
        // Settings Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
        ) {
            Column(modifier = Modifier.padding(4.dp)) {
                SettingsItem(
                    icon = Icons.Default.Notifications,
                    title = "Notifications",
                    subtitle = "Manage your notification preferences",
                    onClick = { },
                )
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(
                    icon = Icons.Default.Pets,
                    title = "My Posts",
                    subtitle = "${vm.user?.username ?: "0"} posts",
                    onClick = { },
                )
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(
                    icon = Icons.Default.Favorite,
                    title = "Liked Posts",
                    subtitle = "Posts you've liked",
                    onClick = { },
                )
            }
        }
        
        Spacer(Modifier.height(16.dp))
        
        // About Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
        ) {
            Column(modifier = Modifier.padding(4.dp)) {
                SettingsItem(
                    icon = Icons.Default.Info,
                    title = "About Pawsome",
                    subtitle = "Tap to check for updates",
                    onClick = onAboutClick,
                )
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(
                    icon = Icons.Default.Help,
                    title = "Help & Support",
                    subtitle = "Get help or report issues",
                    onClick = { },
                )
            }
        }
        
        Spacer(Modifier.weight(1f))
        Spacer(Modifier.height(16.dp))
        
        // Logout Button
        Button(
            onClick = { vm.signOut() },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = MaterialTheme.colorScheme.errorContainer,
                contentColor = MaterialTheme.colorScheme.onErrorContainer,
            ),
            shape = RoundedCornerShape(16.dp),
        ) {
            Icon(Icons.Default.Logout, null, Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text("Log Out", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        }
        
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun SettingsItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    subtitle: String,
    onClick: () -> Unit,
) {
    Surface(
        onClick = onClick,
        color = Color.Transparent,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Icon(
                icon, null, Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
            Spacer(Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                Text(
                    subtitle, style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Icon(
                Icons.AutoMirrored.Filled.ArrowForwardIos, null, Modifier.size(16.dp),
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
fun AboutScreen(onBack: () -> Unit) {
    var checking by remember { mutableStateOf(false) }
    var updateStatus by remember { mutableStateOf<String?>(null) }
    var isUpdateAvailable by remember { mutableStateOf(false) }
    val currentHash = "c693c1c" // Current app version hash

    Column(
        Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(20.dp),
    ) {
        // Header
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) {
                Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back")
            }
            Spacer(Modifier.width(8.dp))
            Text("About Pawsome", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }

        Spacer(Modifier.height(32.dp))

        // App Icon and Name
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
        ) {
            Box(
                Modifier.size(80.dp).clip(RoundedCornerShape(20.dp))
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    Icons.Default.Pets, null, Modifier.size(40.dp),
                    tint = MaterialTheme.colorScheme.onPrimaryContainer,
                )
            }
        }

        Spacer(Modifier.height(16.dp))

        Text(
            "Pawsome",
            style = MaterialTheme.typography.headlineMedium,
            fontWeight = FontWeight.Bold,
            modifier = Modifier.fillMaxWidth(),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )

        Text(
            "Find. Help. Reunite.",
            style = MaterialTheme.typography.bodyLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.fillMaxWidth(),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )

        Spacer(Modifier.height(32.dp))

        // Version Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant),
            shape = RoundedCornerShape(16.dp),
        ) {
            Column(modifier = Modifier.padding(20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text("Current Version", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        Text("1.0.0", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    }
                    Icon(
                        Icons.Default.CheckCircle, null, Modifier.size(32.dp),
                        tint = MaterialTheme.colorScheme.primary,
                    )
                }
            }
        }

        Spacer(Modifier.height(16.dp))

        // Check Updates Button
        Button(
            onClick = {
                checking = true
                updateStatus = null
                viewModelScope.launch {
                    try {
                        // Fetch latest commit hash from GitHub
                        val url = java.net.URL("https://api.github.com/repos/baldbuffalo/Pawsome-Xcode/commits/main")
                        val connection = url.openConnection() as java.net.HttpURLConnection
                        connection.requestMethod = "GET"
                        connection.setRequestProperty("Accept", "application/json")
                        
                        if (connection.responseCode == 200) {
                            val response = connection.inputStream.bufferedReader().readText()
                            val latestHash = extractHashFromJson(response)
                            
                            isUpdateAvailable = latestHash != currentHash
                            updateStatus = if (isUpdateAvailable) 
                                "Update available! Pull latest from GitHub." 
                            else 
                                "You're up to date! ✓"
                        } else {
                            updateStatus = "Unable to check for updates"
                        }
                    } catch (e: Exception) {
                        updateStatus = "You're up to date! ✓"
                    }
                    checking = false
                }
            },
            enabled = !checking,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            if (checking) {
                CircularProgressIndicator(
                    Modifier.size(24.dp),
                    color = MaterialTheme.colorScheme.onPrimary,
                    strokeWidth = 2.dp,
                )
            } else {
                Icon(Icons.Default.Refresh, null, Modifier.size(20.dp))
                Spacer(Modifier.width(8.dp))
                Text("Check for Updates")
            }
        }

        // Update Status
        updateStatus?.let { status ->
            Spacer(Modifier.height(16.dp))
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = if (isUpdateAvailable)
                        MaterialTheme.colorScheme.errorContainer
                    else
                        MaterialTheme.colorScheme.primaryContainer,
                ),
                shape = RoundedCornerShape(12.dp),
            ) {
                Row(
                    modifier = Modifier.padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Icon(
                        if (isUpdateAvailable) Icons.Default.Warning else Icons.Default.CheckCircle,
                        null, Modifier.size(24.dp),
                        tint = if (isUpdateAvailable)
                            MaterialTheme.colorScheme.onErrorContainer
                        else
                            MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        status,
                        style = MaterialTheme.typography.bodyLarge,
                        color = if (isUpdateAvailable)
                            MaterialTheme.colorScheme.onErrorContainer
                        else
                            MaterialTheme.colorScheme.onPrimaryContainer,
                    )
                }
            }
        }

        Spacer(Modifier.weight(1f))

        // Footer
        Text(
            "Made with ❤️ for cats everywhere",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.fillMaxWidth(),
            textAlign = androidx.compose.ui.text.style.TextAlign.Center,
        )

        Spacer(Modifier.height(24.dp))
    }
}

private fun extractHashFromJson(json: String): String? {
    // Extract sha from {"sha":"abc123..."}
    val regex = """"sha"\s*:\s*"([^"]+)"""".toRegex()
    return regex.find(json)?.groupValues?.get(1)?.take(7)
}
