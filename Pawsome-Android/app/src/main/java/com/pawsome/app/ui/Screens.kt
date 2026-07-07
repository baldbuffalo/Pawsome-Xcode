package com.pawsome.app.ui

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import com.pawsome.app.R
import com.pawsome.app.model.Post

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

    Column(Modifier.fillMaxSize().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
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
    }
}

@Composable
fun ProfileScreen(vm: AppViewModel) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        Spacer(Modifier.height(12.dp))
        AsyncImage(
            vm.user?.profilePic?.ifBlank { null }, null,
            Modifier.size(110.dp).clip(CircleShape), contentScale = ContentScale.Crop,
        )
        Text(vm.user?.username ?: "User", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        Spacer(Modifier.weight(1f))
        Button(
            onClick = { vm.signOut() },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFDC2626)),
            modifier = Modifier.fillMaxWidth(),
        ) { Text("Log Out") }
    }
}
