package com.example.pawsome

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.core.app.ActivityCompat
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.ChatBubbleOutline
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.pawsome.ui.AdminScreen
import com.example.pawsome.ui.AboutScreen
import com.example.pawsome.ui.AppViewModel
import com.example.pawsome.ui.ChatScreen
import com.example.pawsome.ui.CreatePostScreen
import com.example.pawsome.ui.FeedScreenWithFoundButton
import com.example.pawsome.ui.HelpScreen
import com.example.pawsome.ui.ImageViewer
import com.example.pawsome.ui.LoginScreen
import com.example.pawsome.ui.PossibleMatchesScreen
import com.example.pawsome.ui.ProfileScreen
import com.example.pawsome.ui.theme.PawsomeTheme
import com.example.pawsome.auth.GoogleAuth

@Suppress("DEPRECATION")
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(NotificationManager::class.java).createNotificationChannel(
                NotificationChannel("pawsome_chat", "Pawsome Chat", NotificationManager.IMPORTANCE_HIGH)
            )
        }
        if (Build.VERSION.SDK_INT >= 33 && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.POST_NOTIFICATIONS), 7001)
        }
        setContent { PawsomeTheme { Surface(Modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) { Root() } } }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == GoogleAuth.REQUEST_CODE) ViewModelProvider(this)[AppViewModel::class.java].handleGoogleSignInResult(resultCode, data)
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
    var showAdmin by remember { mutableStateOf(false) }
    var imageToView by remember { mutableStateOf<String?>(null) }

    BackHandler {
        when {
            imageToView != null -> imageToView = null
            showAdmin -> showAdmin = false
            showHelp -> showHelp = false
            showAbout -> showAbout = false
            creating -> creating = false
            vm.activeConversationId != null -> vm.closeConversation()
            vm.pendingFoundPostId != null -> vm.dismissMatches()
            tab != 0 -> tab = 0
            else -> Unit
        }
    }

    when {
        showAdmin -> AdminScreen { showAdmin = false }
        showAbout -> AboutScreen { showAbout = false }
        showHelp -> HelpScreen { showHelp = false }
        vm.pendingFoundPostId != null -> PossibleMatchesScreen(vm, vm.pendingFoundPostId!!, { vm.dismissMatches() })
        else -> Scaffold(bottomBar = {
            NavigationBar {
                NavigationBarItem(tab == 0 && !creating, { tab = 0; creating = false }, { Icon(Icons.Filled.Home, null) }, label = { Text("Home") })
                NavigationBarItem(tab == 1 && !creating, { tab = 1; creating = false }, { Icon(Icons.Filled.ChatBubbleOutline, null) }, label = { Text("Chat") })
                NavigationBarItem(tab == 2 && !creating, { tab = 2; creating = false }, { Icon(Icons.Filled.Person, null) }, label = { Text("Profile") })
                if (vm.isAdmin) NavigationBarItem(false, { showAdmin = true }, { Icon(Icons.Filled.AdminPanelSettings, null) }, label = { Text("Admin") })
            }
        }) { paddingValues ->
            Box(Modifier.fillMaxSize().padding(paddingValues)) {
                when {
                    creating -> CreatePostScreen(vm) { creating = false }
                    tab == 1 -> ChatScreen(vm)
                    tab == 2 -> ProfileScreen(vm, { showAbout = true }, { showHelp = true }, { showAdmin = true })
                    else -> FeedScreenWithFoundButton(vm, { creating = true }, { imageToView = it })
                }
            }
        }
    }
    imageToView?.let { url -> ImageViewer(url) { imageToView = null } }
}
