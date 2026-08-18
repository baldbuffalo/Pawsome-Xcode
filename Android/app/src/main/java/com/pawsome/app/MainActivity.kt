package com.example.pawsome

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
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
import com.example.pawsome.ui.AboutScreen
import com.example.pawsome.ui.AppViewModel
import com.example.pawsome.ui.CreatePostScreen
import com.example.pawsome.ui.FeedScreen
import com.example.pawsome.ui.HelpScreen
import com.example.pawsome.ui.ImageViewer
import com.example.pawsome.ui.LoginScreen
import com.example.pawsome.ui.ProfileScreen
import com.example.pawsome.ui.theme.PawsomeTheme

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
    }
}

@Composable
private fun Root(vm: AppViewModel = viewModel()) {
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
    var showAbout by remember { mutableStateOf(false) }
    var showHelp by remember { mutableStateOf(false) }
    var imageToView by remember { mutableStateOf<String?>(null) }

    // Global back handler - handles all back navigation
    BackHandler {
        when {
            imageToView != null -> imageToView = null
            showHelp -> showHelp = false
            showAbout -> showAbout = false
            creating -> creating = false
            tab == 1 -> { tab = 0 }
            else -> { /* let system handle exit */ }
        }
    }

    when {
        showAbout -> AboutScreen { showAbout = false }
        showHelp -> HelpScreen { showHelp = false }
        else -> {
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
            ) { paddingValues ->
                Box(Modifier.fillMaxSize().padding(paddingValues)) {
                    when {
                        creating -> CreatePostScreen(vm) { creating = false }
                        tab == 1 -> ProfileScreen(vm, { showAbout = true }, { showHelp = true })
                        else -> FeedScreen(vm, { creating = true }, { imageToView = it })
                    }
                }
            }
        }
    }

    // Image viewer as overlay
    imageToView?.let { url ->
        ImageViewer(url) { imageToView = null }
    }
}
