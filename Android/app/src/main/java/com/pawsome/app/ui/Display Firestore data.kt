package com.example.pawsome.ui

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.*
import androidx.compose.foundation.gestures.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ArrowForwardIos
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import coil.compose.AsyncImage
import com.example.pawsome.R
import com.example.pawsome.model.Post
import com.example.pawsome.model.PostStatus
import com.example.pawsome.ui.theme.*
import kotlinx.coroutines.launch

// ============== LOGIN SCREEN ==============

@Composable
fun LoginScreen(vm: AppViewModel) {
    val context = LocalContext.current
    
    Box(
        Modifier.fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary.copy(alpha = 0.1f),
                        MaterialTheme.colorScheme.background,
                        MaterialTheme.colorScheme.secondary.copy(alpha = 0.05f),
                    )
                )
            ),
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.TopEnd) {
            Text("🐾", fontSize = 120.sp, modifier = Modifier.padding(24.dp).padding(top = 60.dp))
        }
        Box(Modifier.fillMaxSize(), contentAlignment = Alignment.BottomStart) {
            Text("🐾", fontSize = 80.sp, modifier = Modifier.padding(24.dp).padding(bottom = 100.dp))
        }
        
        Card(
            Modifier.widthIn(max = 400.dp).padding(24.dp),
            shape = RoundedCornerShape(28.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp),
        ) {
            Column(
                Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                Box(
                    Modifier.size(100.dp).clip(RoundedCornerShape(24.dp))
                        .background(Brush.linearGradient(colors = listOf(CatOrange, BrandPurple))),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Default.Pets, null, Modifier.size(56.dp), tint = Color.White)
                }
                
                Text("🐱 Pawsome", style = MaterialTheme.typography.headlineLarge, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
                Text("Help lost cats find their way home", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant, textAlign = TextAlign.Center)
                
                Spacer(Modifier.height(12.dp))
                
                Button(
                    onClick = { vm.signIn(context) },
                    enabled = !vm.isBusy,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.White),
                ) {
                    if (vm.busyGoogle) {
                        CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp, color = Color.Gray)
                    } else {
                        Image(painterResource(R.drawable.ic_google), null, Modifier.size(24.dp))
                        Spacer(Modifier.width(12.dp))
                        Text("Continue with Google", color = Color.DarkGray, fontWeight = FontWeight.SemiBold)
                    }
                }
                
                Button(
                    onClick = { vm.signInTwitter(context) },
                    enabled = !vm.isBusy,
                    modifier = Modifier.fillMaxWidth().height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Black),
                ) {
                    if (vm.busyTwitter) {
                        CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp, color = Color.White)
                    } else {
                        Text("𝕏", fontSize = 20.sp, fontWeight = FontWeight.Bold)
                        Spacer(Modifier.width(12.dp))
                        Text("Continue with X", color = Color.White, fontWeight = FontWeight.SemiBold)
                    }
                }
                
                vm.error?.let { Text(it, color = MaterialTheme.colorScheme.error, fontSize = 13.sp, textAlign = TextAlign.Center) }
            }
        }
    }
}

// ============== IMAGE VIEWER (Instagram-like zoom) ==============

@Composable
fun ImageViewer(imageUrl: String, onDismiss: () -> Unit) {
    var scale by remember { mutableFloatStateOf(1f) }
    var offset by remember { mutableStateOf(Offset.Zero) }
    
    Dialog(
        onDismissRequest = { onDismiss() },
        properties = DialogProperties(usePlatformDefaultWidth = false)
    ) {
        Box(
            Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.95f)).clickable { onDismiss() },
            contentAlignment = Alignment.Center,
        ) {
            IconButton(
                onClick = onDismiss,
                modifier = Modifier.align(Alignment.TopEnd).padding(16.dp)
            ) {
                Icon(Icons.Default.Close, "Close", tint = Color.White, modifier = Modifier.size(28.dp))
            }
            
            Box(
                modifier = Modifier.fillMaxWidth().wrapContentHeight(),
                contentAlignment = Alignment.Center,
            ) {
                AsyncImage(
                    imageUrl, null,
                    modifier = Modifier
                        .fillMaxWidth()
                        .pointerInput(Unit) {
                            detectTapGestures(
                                onDoubleTap = { tapOffset ->
                                    if (scale > 1f) {
                                        scale = 1f
                                        offset = Offset.Zero
                                    } else {
                                        val centerX = size.width / 2f
                                        val centerY = size.height / 2f
                                        offset = Offset(
                                            x = (centerX - tapOffset.x) * 2f,
                                            y = (centerY - tapOffset.y) * 2f,
                                        )
                                        scale = 2.5f
                                    }
                                },
                                onTap = {
                                    if (scale > 1f) {
                                        scale = 1f
                                        offset = Offset.Zero
                                    }
                                }
                            )
                        }
                        .pointerInput(Unit) {
                            detectTransformGestures { _, pan, zoom, _ ->
                                val newScale = (scale * zoom).coerceIn(1f, 5f)
                                if (newScale <= 1f) {
                                    scale = 1f
                                    offset = Offset.Zero
                                } else {
                                    scale = newScale
                                    val maxX = (size.width * (scale - 1)) / 2
                                    val maxY = (size.height * (scale - 1)) / 2
                                    offset = Offset(
                                        x = (offset.x + pan.x).coerceIn(-maxX, maxX),
                                        y = (offset.y + pan.y).coerceIn(-maxY, maxY),
                                    )
                                }
                            }
                        }
                        .graphicsLayer(
                            scaleX = scale,
                            scaleY = scale,
                            translationX = offset.x,
                            translationY = offset.y,
                        ),
                    contentScale = ContentScale.Fit,
                )
            }
        }
    }
}

// ============== FEED SCREEN ==============

@Composable
fun FeedScreen(vm: AppViewModel, onCreate: () -> Unit, onImageClick: (String) -> Unit) {
    var selectedFilter by remember { mutableStateOf<PostStatus?>(null) }
    
    val filteredPosts = remember(vm.posts, selectedFilter) {
        if (selectedFilter == null) vm.posts else vm.posts.filter { it.status == selectedFilter }
    }

    Column(Modifier.fillMaxSize()) {
        LazyRow(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            item {
                FilterChip(
                    selected = selectedFilter == null,
                    onClick = { selectedFilter = null },
                    label = { Text("All 🐾") },
                    colors = FilterChipDefaults.filterChipColors(selectedContainerColor = BrandPurple, selectedLabelColor = Color.White),
                )
            }
            items(PostStatus.entries.toTypedArray()) { status ->
                FilterChip(
                    selected = selectedFilter == status,
                    onClick = { selectedFilter = if (selectedFilter == status) null else status },
                    label = { Text("${status.emoji} ${status.displayName}") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = when (status) { PostStatus.LOST -> LostRed; PostStatus.FOUND -> FoundGreen; PostStatus.REUNITED -> ReunitedGold },
                        selectedLabelColor = Color.White,
                    ),
                )
            }
        }
        
        Button(
            onClick = onCreate,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(52.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            Icon(Icons.Default.Add, null)
            Spacer(Modifier.width(8.dp))
            Text("Create a new post", fontWeight = FontWeight.SemiBold)
        }
        
        Spacer(Modifier.height(8.dp))
        
        if (vm.loading && vm.posts.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        } else if (filteredPosts.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("😿", fontSize = 64.sp)
                    Spacer(Modifier.height(16.dp))
                    Text("No cats found", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("Be the first to post!", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                items(filteredPosts, key = { it.id }) { p -> PostCard(p, vm.uid, { vm.toggleLike(p) }, { vm.deletePost(p) }, { onImageClick(p.imageUrl) }) }
            }
        }
    }
}

// ============== POST CARD ==============

@Composable
private fun PostCard(post: Post, uid: String?, onLike: () -> Unit, onDelete: () -> Unit, onImageClick: () -> Unit) {
    val statusColor = when (post.status) { PostStatus.LOST -> LostRed; PostStatus.FOUND -> FoundGreen; PostStatus.REUNITED -> ReunitedGold }
    
    Card(
        Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp),
    ) {
        Column {
            Row(Modifier.fillMaxWidth().padding(14.dp), verticalAlignment = Alignment.CenterVertically) {
                AsyncImage(post.ownerProfilePic.ifBlank { null }, null, Modifier.size(44.dp).clip(CircleShape), contentScale = ContentScale.Crop)
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(post.ownerUsername, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                        Spacer(Modifier.width(8.dp))
                        Surface(shape = RoundedCornerShape(8.dp), color = statusColor.copy(alpha = 0.15f)) {
                            Text("${post.status.emoji} ${post.status.displayName}", modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = statusColor)
                        }
                    }
                    Row {
                        Text(post.timeAgo, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        if (post.location.isNotBlank()) {
                            Text(" • ", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Icon(Icons.Default.LocationOn, null, Modifier.size(12.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text(post.location, fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 1)
                        }
                    }
                }
                if (post.ownerUid == uid) IconButton(onClick = onDelete) { Icon(Icons.Default.Delete, "Delete", tint = MaterialTheme.colorScheme.error) }
            }
            
            Box {
                AsyncImage(post.imageUrl, null, Modifier.fillMaxWidth().height(280.dp).clickable { onImageClick() }, contentScale = ContentScale.Crop)
                Surface(modifier = Modifier.padding(12.dp).align(Alignment.TopEnd), shape = RoundedCornerShape(10.dp), color = statusColor) {
                    Text(post.status.displayName.uppercase(), modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp), fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.White)
                }
            }
            
            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(post.catName, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                    if (post.age.isNotBlank()) {
                        Spacer(Modifier.width(8.dp))
                        Surface(shape = RoundedCornerShape(8.dp), color = MaterialTheme.colorScheme.primaryContainer) {
                            Text("${post.age} yrs", modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp), fontSize = 12.sp, color = MaterialTheme.colorScheme.onPrimaryContainer)
                        }
                    }
                }
                if (post.description.isNotBlank()) {
                    Spacer(Modifier.height(6.dp))
                    Text(post.description, color = MaterialTheme.colorScheme.onSurfaceVariant, maxLines = 3)
                }
            }
            
            Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp).padding(bottom = 8.dp), verticalAlignment = Alignment.CenterVertically) {
                val liked = post.isLikedBy(uid)
                FilledTonalButton(
                    onClick = onLike,
                    colors = ButtonDefaults.filledTonalButtonColors(containerColor = if (liked) LostRed.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surfaceVariant),
                    shape = RoundedCornerShape(12.dp),
                ) {
                    Icon(if (liked) Icons.Default.Favorite else Icons.Default.FavoriteBorder, null, tint = if (liked) LostRed else MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("${post.likeCount} likes", color = if (liked) LostRed else MaterialTheme.colorScheme.onSurfaceVariant)
                }
                Spacer(Modifier.width(12.dp))
                FilledTonalButton(onClick = { }, shape = RoundedCornerShape(12.dp)) {
                    Icon(Icons.Default.ChatBubbleOutline, null, modifier = Modifier.size(20.dp))
                    Spacer(Modifier.width(6.dp))
                    Text("${post.commentCount} comments")
                }
            }
        }
    }
}

// ============== CREATE POST SCREEN ==============

@Composable
fun CreatePostScreen(vm: AppViewModel, onBack: () -> Unit) {
    var name by remember { mutableStateOf("") }
    var age by remember { mutableStateOf("") }
    var desc by remember { mutableStateOf("") }
    var location by remember { mutableStateOf("") }
    var uri by remember { mutableStateOf<android.net.Uri?>(null) }
    var status by remember { mutableStateOf(PostStatus.LOST) }
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri = it }

    Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(16.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back") }
            Text("Create Post", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }
        Spacer(Modifier.height(16.dp))
        OutlinedTextField(name, { name = it }, label = { Text("Cat name") }, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(age, { age = it }, label = { Text("Age") }, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(desc, { desc = it }, label = { Text("Description") }, modifier = Modifier.fillMaxWidth().height(120.dp))
        Spacer(Modifier.height(12.dp))
        OutlinedTextField(location, { location = it }, label = { Text("Location") }, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(12.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            PostStatus.entries.forEach { s ->
                FilterChip(selected = status == s, onClick = { status = s }, label = { Text(s.displayName) })
            }
        }
        Spacer(Modifier.height(12.dp))
        Button(onClick = { picker.launch("image/*") }, modifier = Modifier.fillMaxWidth()) { Text(if (uri == null) "Choose image" else "Image selected") }
        Spacer(Modifier.height(16.dp))
        Button(
            onClick = {
                scope.launch {
                    vm.createPost(name, age, desc, location, status, uri)
                    onBack()
                }
            },
            enabled = name.isNotBlank() && uri != null && !vm.isBusy,
            modifier = Modifier.fillMaxWidth().height(52.dp),
        ) { Text("Post") }
    }
}
