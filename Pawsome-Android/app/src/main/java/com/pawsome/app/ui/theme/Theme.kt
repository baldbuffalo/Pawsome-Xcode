package com.example.pawsome.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

val BrandPurple = Color(0xFF7C3AED)

private val LightColors = lightColorScheme(primary = BrandPurple, secondary = BrandPurple)
private val DarkColors = darkColorScheme(primary = BrandPurple, secondary = BrandPurple)

@Composable
fun PawsomeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        content = content,
    )
}
