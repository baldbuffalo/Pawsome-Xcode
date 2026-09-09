package com.example.pawsome.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.tasks.await
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject

private const val FUNCTIONS_BASE = "https://europe-west1-pawsome-90cb3.cloudfunctions.net/"

@Composable
fun AdminScreen(onBack: () -> Unit = {}) {
    var posts by remember { mutableStateOf<List<Pair<String, JSONObject>>>(emptyList()) }
    var postCount by remember { mutableStateOf(0) }
    var userCount by remember { mutableStateOf(0) }
    var maintenance by remember { mutableStateOf(false) }
    var ads by remember { mutableStateOf(true) }
    var title by remember { mutableStateOf("") }
    var body by remember { mutableStateOf("") }
    var busy by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf("") }
    val scope = rememberCoroutineScope()

    suspend fun call(name: String, data: JSONObject = JSONObject()): JSONObject = withContext(Dispatchers.IO) {
        val user = FirebaseAuth.getInstance().currentUser ?: error("Not signed in")
        val token = user.getIdToken(false).await().token ?: error("Could not get Firebase token")
        val client = OkHttpClient()
        val request = Request.Builder().url(FUNCTIONS_BASE + name)
            .addHeader("Authorization", "Bearer $token")
            .post(JSONObject().put("data", data).toString().toRequestBody("application/json".toMediaType()))
            .build()
        client.newCall(request).execute().use { response ->
            val text = response.body?.string().orEmpty()
            if (!response.isSuccessful) error(text.ifBlank { "Firebase function failed" })
            JSONObject(text).optJSONObject("data") ?: JSONObject()
        }
    }

    suspend fun refresh() {
        busy = true; message = ""
        try {
            val stats = call("adminGetStats")
            val p = call("adminListDocuments", JSONObject().put("collectionPath", "posts").put("limit", 100))
            val c = call("adminGetAppConfig")
            postCount = stats.optInt("posts")
            userCount = stats.optInt("users")
            val docs = p.optJSONArray("documents")
            posts = buildList {
                if (docs != null) for (i in 0 until docs.length()) {
                    val d = docs.getJSONObject(i); add(d.optString("path") to d.optJSONObject("fields").orEmpty())
                }
            }
            val fields = c.optJSONObject("fields") ?: JSONObject()
            maintenance = fields.optBoolean("maintenanceMode", false)
            ads = fields.optBoolean("adsEnabled", true)
            title = fields.optString("announcementTitle", "")
            body = fields.optString("announcementBody", "")
        } catch (e: Exception) { message = e.message ?: "Admin request failed" }
        busy = false
    }

    Column(Modifier.fillMaxSize().padding(20.dp)) {
        Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
            Text("Admin", style = MaterialTheme.typography.headlineMedium)
            IconButton(onClick = { scope.launch { refresh() } }, enabled = !busy) { Icon(Icons.Default.Refresh, "Refresh") }
        }
        Text("Firebase: pawsome-90cb3", color = MaterialTheme.colorScheme.onSurfaceVariant)
        Spacer(Modifier.height(16.dp))
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            AssistChip(onClick = {}, label = { Text("Posts: $postCount") })
            AssistChip(onClick = {}, label = { Text("Users: $userCount") })
        }
        Spacer(Modifier.height(12.dp))
        LazyColumn(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            item {
                Text("App settings", style = MaterialTheme.typography.titleMedium)
                SwitchRow("Maintenance mode", maintenance) { maintenance = it }
                SwitchRow("Ads enabled", ads) { ads = it }
                OutlinedTextField(title, { title = it }, label = { Text("Announcement title") }, modifier = Modifier.fillMaxWidth())
                OutlinedTextField(body, { body = it }, label = { Text("Announcement message") }, modifier = Modifier.fillMaxWidth().padding(top = 8.dp), minLines = 3)
                Button(onClick = { scope.launch { busy = true; try { call("adminSetAppConfig", JSONObject().put("fields", JSONObject().put("maintenanceMode", maintenance).put("adsEnabled", ads).put("announcementTitle", title.trim()).put("announcementBody", body.trim()))); message = "Settings saved." } catch(e: Exception) { message = e.message ?: "Save failed" }; busy = false } }, enabled = !busy) { Text("Save settings") }
                Spacer(Modifier.height(20.dp)); Text("Posts", style = MaterialTheme.typography.titleMedium)
            }
            items(posts, key = { it.first }) { (path, fields) ->
                Card(Modifier.fillMaxWidth()) {
                    Row(Modifier.fillMaxWidth().padding(12.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        Column(Modifier.weight(1f)) {
                            Text(fields.optString("CatName", fields.optString("catName", "Untitled")), style = MaterialTheme.typography.titleSmall)
                            Text(fields.optString("status", "UNKNOWN"), color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        IconButton(onClick = { scope.launch { busy = true; try { call("adminDeleteDocument", JSONObject().put("path", path)); refresh() } catch(e: Exception) { message = e.message ?: "Delete failed" }; busy = false } }) { Icon(Icons.Default.Delete, "Delete") }
                    }
                }
            }
        }
        if (message.isNotEmpty()) Text(message, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
    LaunchedEffect(Unit) { refresh() }
}

@Composable
private fun SwitchRow(label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) { Text(label); Switch(checked, onCheckedChange) }
}

private fun JSONObject.orEmpty() = this
