package com.example.pawsome.ui

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.Pets
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.example.pawsome.model.Post
import com.example.pawsome.model.PostStatus
import com.example.pawsome.ui.theme.*

@Composable
fun FeedScreenWithFoundButton(
    vm: AppViewModel,
    onCreate: () -> Unit,
    onImageClick: (String) -> Unit
) {
    var selectedFilter by remember { mutableStateOf<PostStatus?>(null) }
    val filteredPosts = remember(vm.posts, selectedFilter) {
        if (selectedFilter == null) vm.posts else vm.posts.filter { it.status == selectedFilter }
    }
    val currentUserNumber = vm.user?.userNumber

    Column(Modifier.fillMaxSize()) {
        LazyRow(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            item {
                FilterChip(
                    selected = selectedFilter == null,
                    onClick = { selectedFilter = null },
                    label = { Text("All 🐾") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = BrandPurple,
                        selectedLabelColor = Color.White
                    )
                )
            }
            items(PostStatus.entries.toTypedArray()) { status ->
                FilterChip(
                    selected = selectedFilter == status,
                    onClick = {
                        selectedFilter = if (selectedFilter == status) null else status
                    },
                    label = { Text("${status.emoji} ${status.displayName}") },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = when (status) {
                            PostStatus.LOST -> LostRed
                            PostStatus.FOUND -> FoundGreen
                            PostStatus.REUNITED -> ReunitedGold
                        },
                        selectedLabelColor = Color.White
                    )
                )
            }
        }

        Button(
            onClick = onCreate,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp).height(52.dp),
            shape = RoundedCornerShape(16.dp)
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
            Box(
                Modifier.fillMaxSize().padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text("😿", fontSize = 64.sp)
                    Spacer(Modifier.height(16.dp))
                    Text(
                        "No cats found",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        "Be the first to post!",
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }
        } else {
            LazyColumn(
                Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(filteredPosts, key = { it.id }) { post ->
                    FoundCatPostCard(
                        post = post,
                        uid = vm.uid,
                        currentUserNumber = currentUserNumber,
                        onLike = { vm.toggleLike(post) },
                        onDelete = { vm.deletePost(post) },
                        onImageClick = { onImageClick(post.imageUrl) },
                        onFoundCat = { vm.checkFoundPostForMatches(post) }
                    )
                }
            }
        }
    }
}

@Composable
private fun FoundCatPostCard(
    post: Post,
    uid: String?,
    currentUserNumber: Int?,
    onLike: () -> Unit,
    onDelete: () -> Unit,
    onImageClick: () -> Unit,
    onFoundCat: () -> Unit
) {
    val statusColor = when (post.status) {
        PostStatus.LOST -> LostRed
        PostStatus.FOUND -> FoundGreen
        PostStatus.REUNITED -> ReunitedGold
    }
    val isOwnPost = currentUserNumber != null && post.userId == currentUserNumber

    Card(
        Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column {
            Row(
                Modifier.fillMaxWidth().padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                AsyncImage(
                    post.profilePic.ifBlank { null },
                    null,
                    Modifier.size(44.dp).clip(CircleShape),
                    contentScale = ContentScale.Crop
                )
                Spacer(Modifier.width(12.dp))
                Column(Modifier.weight(1f)) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Text(post.username, fontWeight = FontWeight.SemiBold, fontSize = 15.sp)
                        Spacer(Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = statusColor.copy(alpha = 0.15f)
                        ) {
                            Text(
                                "${post.status.emoji} ${post.status.displayName}",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.SemiBold,
                                color = statusColor
                            )
                        }
                    }
                    Row {
                        Text(
                            post.timeAgo,
                            fontSize = 12.sp,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        if (post.location.isNotBlank()) {
                            Text(" • ", fontSize = 12.sp, color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Icon(
                                Icons.Default.LocationOn,
                                null,
                                Modifier.size(12.dp),
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                post.location,
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 1
                            )
                        }
                    }
                }
                if (isOwnPost) {
                    IconButton(onClick = onDelete) {
                        Icon(
                            Icons.Default.Delete,
                            "Delete",
                            tint = MaterialTheme.colorScheme.error
                        )
                    }
                }
            }

            Box {
                AsyncImage(
                    post.imageUrl,
                    null,
                    Modifier.fillMaxWidth().height(280.dp).clickable { onImageClick() },
                    contentScale = ContentScale.Crop
                )
                Surface(
                    modifier = Modifier.padding(12.dp).align(Alignment.TopEnd),
                    shape = RoundedCornerShape(10.dp),
                    color = statusColor
                ) {
                    Text(
                        post.status.displayName.uppercase(),
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                        fontSize = 11.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
            }

            Column(Modifier.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        post.catName,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    if (post.age.isNotBlank()) {
                        Spacer(Modifier.width(8.dp))
                        Surface(
                            shape = RoundedCornerShape(8.dp),
                            color = MaterialTheme.colorScheme.primaryContainer
                        ) {
                            Text(
                                "${post.age} yrs",
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
                                fontSize = 12.sp,
                                color = MaterialTheme.colorScheme.onPrimaryContainer
                            )
                        }
                    }
                }
                if (post.description.isNotBlank()) {
                    Spacer(Modifier.height(6.dp))
                    Text(
                        post.description,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        maxLines = 3
                    )
                }
            }

            Row(
                Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                val liked = post.isLikedBy(uid)
                FilledTonalButton(
                    onClick = onLike,
                    colors = ButtonDefaults.filledTonalButtonColors(
                        containerColor = if (liked) LostRed.copy(alpha = 0.15f)
                        else MaterialTheme.colorScheme.surfaceVariant
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(
                        if (liked) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                        null,
                        tint = if (liked) LostRed else MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text(
                        if (post.likeCount == 1) "1 like" else "${post.likeCount} likes",
                        color = if (liked) LostRed else MaterialTheme.colorScheme.onSurfaceVariant
                    )
                }
            }

            if (post.status == PostStatus.FOUND && isOwnPost) {
                OutlinedButton(
                    onClick = onFoundCat,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 4.dp),
                    shape = RoundedCornerShape(12.dp),
                    border = BorderStroke(1.dp, FoundGreen)
                ) {
                    Icon(Icons.Default.Pets, null, tint = FoundGreen)
                    Spacer(Modifier.width(8.dp))
                    Text(
                        "I Found This Cat",
                        color = FoundGreen,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }

            Spacer(Modifier.height(8.dp))
        }
    }
}
