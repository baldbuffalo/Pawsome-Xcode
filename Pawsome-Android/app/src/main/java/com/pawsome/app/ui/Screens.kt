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
            
            // Image container that matches image aspect ratio - gestures ONLY on this
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
fun FeedScreen(vm: AppViewModel, onCreate: () -> Unit) {
    var selectedFilter by remember { mutableStateOf<PostStatus?>(null) }
    var imageToView by remember { mutableStateOf<String?>(null) }
    
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
        
        // Show posts immediately when available, loading indicator only on first load
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
                items(filteredPosts, key = { it.id }) { p -> PostCard(p, vm.uid, { vm.toggleLike(p) }, { vm.deletePost(p) }, { imageToView = p.imageUrl }) }
            }
        }
    }
    
    imageToView?.let { url ->
        ImageViewer(url) { imageToView = null }
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
            
            // Clickable image
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
    var selectedStatus by remember { mutableStateOf(PostStatus.LOST) }
    val picker = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri = it }

    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).verticalScroll(rememberScrollState())) {
        Row(Modifier.fillMaxWidth().background(Brush.horizontalGradient(listOf(CatOrange, BrandPurple))).padding(16.dp).padding(top = 24.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back", tint = Color.White) }
            Spacer(Modifier.width(8.dp))
            Text("Create Post", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold, color = Color.White)
        }
        
        Column(Modifier.padding(20.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            Text("What's the status?", fontWeight = FontWeight.SemiBold)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                PostStatus.entries.filter { it != PostStatus.REUNITED }.forEach { status ->
                    val isSelected = selectedStatus == status
                    val color = if (status == PostStatus.LOST) LostRed else FoundGreen
                    Card(
                        onClick = { selectedStatus = status },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = if (isSelected) color else MaterialTheme.colorScheme.surfaceVariant),
                        border = if (isSelected) null else BorderStroke(2.dp, color.copy(alpha = 0.3f)),
                    ) {
                        Column(Modifier.fillMaxWidth().padding(16.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(status.emoji, fontSize = 32.sp)
                            Spacer(Modifier.height(4.dp))
                            Text(status.displayName, fontWeight = FontWeight.SemiBold, color = if (isSelected) Color.White else color)
                        }
                    }
                }
            }
            
            if (uri != null) {
                Box {
                    AsyncImage(uri, null, Modifier.fillMaxWidth().height(220.dp), contentScale = ContentScale.Fit)
                    IconButton(onClick = { uri = null }, modifier = Modifier.align(Alignment.TopEnd).padding(8.dp)) {
                        Surface(shape = CircleShape, color = Color.Black.copy(alpha = 0.6f)) {
                            Icon(Icons.Default.Close, "Remove", tint = Color.White, modifier = Modifier.padding(8.dp))
                        }
                    }
                }
            } else {
                OutlinedCard(onClick = { picker.launch("image/*") }, modifier = Modifier.fillMaxWidth().height(180.dp), shape = RoundedCornerShape(16.dp), border = BorderStroke(2.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.5f))) {
                    Column(Modifier.fillMaxSize(), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                        Icon(Icons.Default.AddAPhoto, null, Modifier.size(48.dp), tint = MaterialTheme.colorScheme.primary)
                        Spacer(Modifier.height(8.dp))
                        Text("Add a photo of the cat", color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            OutlinedButton(onClick = { picker.launch("image/*") }, modifier = Modifier.fillMaxWidth()) {
                Icon(if (uri == null) Icons.Default.AddAPhoto else Icons.Default.Refresh, null)
                Spacer(Modifier.width(8.dp))
                Text(if (uri == null) "Choose Image" else "Change Image")
            }
            
            OutlinedTextField(name, { name = it }, label = { Text("Cat Name") }, modifier = Modifier.fillMaxWidth(), singleLine = true, leadingIcon = { Icon(Icons.Default.Pets, null) })
            OutlinedTextField(age, { age = it }, label = { Text("Age (years)") }, modifier = Modifier.fillMaxWidth(), singleLine = true, leadingIcon = { Icon(Icons.Default.Cake, null) })
            OutlinedTextField(location, { location = it }, label = { Text("Location (optional)") }, modifier = Modifier.fillMaxWidth(), singleLine = true, leadingIcon = { Icon(Icons.Default.LocationOn, null) })
            OutlinedTextField(desc, { desc = it }, label = { Text("Description") }, modifier = Modifier.fillMaxWidth(), minLines = 3, leadingIcon = { Icon(Icons.Default.Description, null) })
            
            vm.error?.let { Text(it, color = MaterialTheme.colorScheme.error, fontSize = 13.sp) }
            
            Spacer(Modifier.height(8.dp))
            
            Button(
                onClick = { uri?.let { vm.createPost(it, name, age, desc, location, selectedStatus, onBack) } },
                enabled = !vm.busyPost && uri != null && name.isNotBlank() && age.isNotBlank() && desc.isNotBlank(),
                modifier = Modifier.fillMaxWidth().height(56.dp),
                shape = RoundedCornerShape(16.dp),
            ) {
                if (vm.busyPost) { CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp) }
                else { Icon(Icons.Default.Send, null); Spacer(Modifier.width(8.dp)); Text("Post ${selectedStatus.emoji}", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold) }
            }
            
            Spacer(Modifier.height(32.dp))
        }
    }
}

// ============== PROFILE SCREEN ==============

@Composable
fun ProfileScreen(vm: AppViewModel, onAboutClick: () -> Unit, onHelpClick: () -> Unit) {
    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).verticalScroll(rememberScrollState()).padding(20.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.height(24.dp))
        
        Box(contentAlignment = Alignment.Center) {
            Box(Modifier.size(120.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) {
                AsyncImage(vm.user?.profilePic?.ifBlank { null }, null, Modifier.size(112.dp).clip(CircleShape), contentScale = ContentScale.Crop)
                if (vm.user?.profilePic.isNullOrBlank()) Icon(Icons.Default.Person, null, Modifier.size(56.dp), tint = MaterialTheme.colorScheme.onPrimaryContainer)
            }
        }
        
        Spacer(Modifier.height(16.dp))
        Text(vm.user?.username ?: "User", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Text("@${vm.user?.username ?: "user"}", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant)
        
        Spacer(Modifier.height(32.dp))
        
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
            StatItem(count = vm.posts.size.toString(), label = "Posts")
            StatItem(count = vm.posts.sumOf { it.likeCount }.toString(), label = "Likes")
            StatItem(count = vm.user?.userNumber?.toString() ?: "?", label = "Member #")
        }
        
        Spacer(Modifier.height(24.dp))
        
        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), shape = RoundedCornerShape(16.dp)) {
            Column(modifier = Modifier.padding(4.dp)) {
                SettingsItem(icon = Icons.Default.Notifications, title = "Notifications", subtitle = "Manage your notification preferences", onClick = { })
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(icon = Icons.Default.Pets, title = "My Posts", subtitle = "${vm.posts.count { it.ownerUid == vm.uid }} posts", onClick = { })
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(icon = Icons.Default.Favorite, title = "Liked Posts", subtitle = "Posts you've liked", onClick = { })
            }
        }
        
        Spacer(Modifier.height(16.dp))
        
        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), shape = RoundedCornerShape(16.dp)) {
            Column(modifier = Modifier.padding(4.dp)) {
                SettingsItem(icon = Icons.Default.Info, title = "About Pawsome", subtitle = "Version 1.0.0", onClick = onAboutClick)
                HorizontalDivider(modifier = Modifier.padding(horizontal = 16.dp), color = MaterialTheme.colorScheme.outline.copy(alpha = 0.3f))
                SettingsItem(icon = Icons.Default.Help, title = "Help & Support", subtitle = "Get help or report issues", onClick = onHelpClick)
            }
        }
        
        Spacer(Modifier.height(32.dp))
        
        // Logout Button - Red and visible
        Button(
            onClick = { vm.signOut() },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            colors = ButtonDefaults.buttonColors(containerColor = LostRed),
            shape = RoundedCornerShape(16.dp),
        ) {
            Icon(Icons.Default.Logout, null, Modifier.size(20.dp), tint = Color.White)
            Spacer(Modifier.width(8.dp))
            Text("Log Out", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = Color.White)
        }
        
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun StatItem(count: String, label: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(count, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)
        Text(label, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun SettingsItem(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String, onClick: () -> Unit) {
    Surface(onClick = onClick, color = Color.Transparent, modifier = Modifier.fillMaxWidth()) {
        Row(modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, null, Modifier.size(24.dp), tint = MaterialTheme.colorScheme.primary)
            Spacer(Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Icon(Icons.AutoMirrored.Filled.ArrowForwardIos, null, Modifier.size(16.dp), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
    }
}

// ============== ABOUT SCREEN ==============

@Composable
fun AboutScreen(onBack: () -> Unit) {
    var checking by remember { mutableStateOf(false) }
    var updateStatus by remember { mutableStateOf<String?>(null) }
    var isUpdateAvailable by remember { mutableStateOf(false) }
    val currentHash = "fe0fe56"
    val scope = rememberCoroutineScope()

    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back") }
            Spacer(Modifier.width(8.dp))
            Text("About Pawsome", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }

        Spacer(Modifier.height(32.dp))

        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.Center) {
            Box(Modifier.size(100.dp).clip(RoundedCornerShape(24.dp)).background(Brush.linearGradient(listOf(CatOrange, BrandPurple))), contentAlignment = Alignment.Center) {
                Icon(Icons.Default.Pets, null, Modifier.size(50.dp), tint = Color.White)
            }
        }

        Spacer(Modifier.height(20.dp))
        Text("Pawsome", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Text("Find. Help. Reunite. 🐱", style = MaterialTheme.typography.bodyLarge, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)

        Spacer(Modifier.height(32.dp))

        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), shape = RoundedCornerShape(16.dp)) {
            Row(Modifier.fillMaxWidth().padding(20.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Column {
                    Text("Current Version", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text("1.0.0", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                }
                Icon(Icons.Default.CheckCircle, null, Modifier.size(32.dp), tint = FoundGreen)
            }
        }

        Spacer(Modifier.height(16.dp))

        Button(
            onClick = {
                checking = true
                updateStatus = null
                scope.launch {
                    try {
                        val url = java.net.URL("https://api.github.com/repos/baldbuffalo/Pawsome-Xcode/commits/main")
                        val connection = url.openConnection() as java.net.HttpURLConnection
                        connection.requestMethod = "GET"
                        connection.setRequestProperty("Accept", "application/json")
                        if (connection.responseCode == 200) {
                            val response = connection.inputStream.bufferedReader().readText()
                            val latestHash = extractHashFromJson(response)
                            isUpdateAvailable = latestHash != currentHash
                            updateStatus = if (isUpdateAvailable) "Update available! Pull latest from GitHub." else "You're up to date! ✓"
                        } else { updateStatus = "Unable to check for updates" }
                    } catch (e: Exception) { updateStatus = "You're up to date! ✓" }
                    checking = false
                }
            },
            enabled = !checking,
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            if (checking) { CircularProgressIndicator(Modifier.size(24.dp), strokeWidth = 2.dp) }
            else { Icon(Icons.Default.Refresh, null, Modifier.size(20.dp)); Spacer(Modifier.width(8.dp)); Text("Check for Updates") }
        }

        updateStatus?.let { status ->
            Spacer(Modifier.height(16.dp))
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(containerColor = if (isUpdateAvailable) LostRedLight else FoundGreenLight),
                shape = RoundedCornerShape(12.dp),
            ) {
                Row(modifier = Modifier.padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(if (isUpdateAvailable) Icons.Default.Warning else Icons.Default.CheckCircle, null, Modifier.size(24.dp), tint = if (isUpdateAvailable) LostRed else FoundGreen)
                    Spacer(Modifier.width(12.dp))
                    Text(status, style = MaterialTheme.typography.bodyLarge)
                }
            }
        }

        Spacer(Modifier.weight(1f))
        Text("Made with ❤️ for cats everywhere", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
    }
}

// ============== HELP SCREEN ==============

@Composable
fun HelpScreen(onBack: () -> Unit) {
    val context = LocalContext.current
    
    Column(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background).padding(20.dp)) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back") }
            Spacer(Modifier.width(8.dp))
            Text("Help & Support", style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
        }

        Spacer(Modifier.height(24.dp))

        Card(Modifier.fillMaxWidth(), colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant), shape = RoundedCornerShape(16.dp)) {
            Column(modifier = Modifier.padding(20.dp)) {
                Text("Need help with Pawsome?", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                Text("If you're experiencing issues or have questions, please report them on GitHub.", color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
        }

        Spacer(Modifier.height(16.dp))

        Button(
            onClick = {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/baldbuffalo/Pawsome-Xcode/issues"))
                context.startActivity(intent)
            },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            Icon(Icons.Default.BugReport, null)
            Spacer(Modifier.width(8.dp))
            Text("Report an Issue on GitHub")
        }

        Spacer(Modifier.height(12.dp))

        OutlinedButton(
            onClick = {
                val intent = Intent(Intent.ACTION_VIEW, Uri.parse("https://github.com/baldbuffalo/Pawsome-Xcode"))
                context.startActivity(intent)
            },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
        ) {
            Icon(Icons.Default.Code, null)
            Spacer(Modifier.width(8.dp))
            Text("View Source Code")
        }

        Spacer(Modifier.weight(1f))
        
        Text("Pawsome v1.0.0", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant, modifier = Modifier.fillMaxWidth(), textAlign = TextAlign.Center)
        Spacer(Modifier.height(24.dp))
    }
}

private fun extractHashFromJson(json: String): String? {
    val regex = """"sha"\s*:\s*"([^"]+)"""".toRegex()
    return regex.find(json)?.groupValues?.get(1)?.take(7)
}
