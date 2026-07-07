package com.pawsome.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.pawsome.app.ui.AppViewModel
import com.pawsome.app.ui.CreatePostScreen
import com.pawsome.app.ui.FeedScreen
import com.pawsome.app.ui.LoginScreen
import com.pawsome.app.ui.ProfileScreen
import com.pawsome.app.ui.theme.PawsomeTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            PawsomeTheme {
                Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
                    Root()
                }
            }
        }
        // Handle Twitter callback if app was launched from deep link
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val uri = intent?.data ?: return
        if (uri.scheme == "pawsome") {
            // Notify the ViewModel about the callback
            // We use a static reference or shared state to pass this
            TwitterCallbackHolder.callbackUri = uri
        }
    }
}

// Holder for Twitter callback URI - simple approach
object TwitterCallbackHolder {
    var callbackUri: android.net.Uri? = null
}

@Composable
private fun Root(vm: AppViewModel = viewModel()) {
    // Poll for Twitter callback when on login screen
    androidx.compose.runtime.LaunchedEffect(Unit) {
        while (true) {
            if (vm.busyTwitter) {
                val uri = TwitterCallbackHolder.callbackUri
                if (uri != null) {
                    TwitterCallbackHolder.callbackUri = null
                    vm.handleTwitterCallback(uri)
                }
            }
            kotlinx.coroutines.delay(100)
        }
    }
    
    when {
        vm.loading -> Box(Modifier.fillMaxSize(), Alignment.Center) { CircularProgressIndicator() }
        !vm.signedIn -> LoginScreen(vm)
        else -> MainScaffold(vm)
    }
}

@Composable
private fun MainScaffold(vm: AppViewModel) {
    var tab by remember { mutableStateOf(0) }
    var creating by remember { mutableStateOf(false) }

    Scaffold(
        bottomBar = {
            NavigationBar {
                NavigationBarItem(
                    selected = tab == 0 && !creating,
                    onClick = { tab = 0; creating = false },
                    icon = { Icon(Icons.Filled.Home, null) },
                    label = { Text("Home") },
                )
                NavigationBarItem(
                    selected = tab == 1,
                    onClick = { tab = 1; creating = false },
                    icon = { Icon(Icons.Filled.Person, null) },
                    label = { Text("Profile") },
                )
            }
        }
    ) { padding ->
        Box(Modifier.fillMaxSize().padding(padding)) {
            when {
                creating -> CreatePostScreen(vm) { creating = false }
                tab == 1 -> ProfileScreen(vm)
                else -> FeedScreen(vm) { creating = true }
            }
        }
    }
}
