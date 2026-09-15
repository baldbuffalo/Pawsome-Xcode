package com.example.pawsome.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun ChatScreen(vm: AppViewModel) {
    val conversations = vm.conversations
    if (vm.activeConversationId != null) {
        ChatConversationScreen(vm)
        return
    }

    Column(Modifier.fillMaxSize()) {
        Text("Chat", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold, modifier = Modifier.padding(20.dp))
        if (vm.chatLoading && conversations.isEmpty()) {
            Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        } else if (conversations.isEmpty()) {
            Box(Modifier.fillMaxSize().padding(32.dp), contentAlignment = Alignment.Center) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Icon(Icons.Default.ChatBubbleOutline, null, Modifier.size(56.dp), tint = MaterialTheme.colorScheme.primary)
                    Text("No chats yet", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
                    Text("When you contact someone about a lost or found cat, your conversation will appear here.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        } else {
            LazyColumn(Modifier.fillMaxSize()) {
                items(conversations, key = { it.id }) { chat ->
                    Surface(onClick = { vm.openConversation(chat.id, chat.otherUid, chat.otherName) }, modifier = Modifier.fillMaxWidth()) {
                        Row(Modifier.padding(horizontal = 20.dp, vertical = 14.dp), verticalAlignment = Alignment.CenterVertically) {
                            Box(Modifier.size(48.dp).clip(CircleShape).background(MaterialTheme.colorScheme.primaryContainer), contentAlignment = Alignment.Center) {
                                Text(chat.otherName.take(1).uppercase(), fontWeight = FontWeight.Bold)
                            }
                            Spacer(Modifier.width(14.dp))
                            Column(Modifier.weight(1f)) {
                                Text(chat.otherName, fontWeight = FontWeight.SemiBold)
                                Text(chat.lastMessage.ifBlank { "Start a conversation" }, maxLines = 1, color = MaterialTheme.colorScheme.onSurfaceVariant, fontSize = 13.sp)
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ChatConversationScreen(vm: AppViewModel) {
    var message by remember { mutableStateOf("") }
    val otherName = vm.activeConversationName ?: "Chat"
    Column(Modifier.fillMaxSize().imePadding()) {
        Row(Modifier.fillMaxWidth().padding(8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = { vm.closeConversation() }) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back") }
            Text(otherName, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
        }
        LazyColumn(Modifier.weight(1f).fillMaxWidth().padding(horizontal = 12.dp), reverseLayout = true) {
            items(vm.activeMessages.reversed(), key = { it.id }) { item ->
                val mine = item.senderUid == vm.uid
                Row(Modifier.fillMaxWidth().padding(vertical = 4.dp), horizontalArrangement = if (mine) Arrangement.End else Arrangement.Start) {
                    Surface(shape = RoundedCornerShape(18.dp), color = if (mine) MaterialTheme.colorScheme.primaryContainer else MaterialTheme.colorScheme.surfaceVariant) {
                        Text(item.text, modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp), color = MaterialTheme.colorScheme.onSurface)
                    }
                }
            }
        }
        Row(Modifier.fillMaxWidth().navigationBarsPadding().padding(10.dp), verticalAlignment = Alignment.CenterVertically) {
            OutlinedTextField(message, { message = it }, Modifier.weight(1f), placeholder = { Text("Message…") }, maxLines = 4)
            IconButton(onClick = { val text = message.trim(); if (text.isNotEmpty()) { message = ""; vm.sendMessage(text) } }) {
                Icon(Icons.AutoMirrored.Filled.Send, "Send")
            }
        }
    }
}

@Composable
fun PossibleMatchesScreen(vm: AppViewModel, foundPostId: String, onDone: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(20.dp)) {
        Text("Possible matches", style = MaterialTheme.typography.headlineMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.size(8.dp))
        Text("These Lost Cat posts may match the cat you found. Choose one only if you think it could be the same cat.", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.size(16.dp))
        if (vm.matchLoading) CircularProgressIndicator()
        else if (vm.possibleMatches.isEmpty()) {
            Text("No possible matches found right now.", modifier = Modifier.padding(vertical = 24.dp))
            Button(onClick = onDone) { Text("Done") }
        } else {
            LazyColumn(Modifier.weight(1f)) {
                items(vm.possibleMatches, key = { it.id }) { post ->
                    Surface(onClick = { vm.notifyPossibleMatch(foundPostId, post) }, modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp), shape = RoundedCornerShape(16.dp), tonalElevation = 2.dp) {
                        Column(Modifier.padding(16.dp)) {
                            Text(post.catName, fontWeight = FontWeight.Bold)
                            Text("Lost by ${post.username}")
                            if (post.location.isNotBlank()) Text("📍 ${post.location}", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            Text("Tap to notify the owner", fontSize = 13.sp, color = MaterialTheme.colorScheme.primary)
                        }
                    }
                }
            }
            Button(onClick = onDone, modifier = Modifier.fillMaxWidth()) { Text("Done") }
        }
    }
}
