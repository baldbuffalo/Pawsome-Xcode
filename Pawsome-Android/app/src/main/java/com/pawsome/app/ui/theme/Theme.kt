package com.example.pawsome.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

// Pawsome Brand Colors
val CatOrange = Color(0xFFFF6B35)
val CatOrangeLight = Color(0xFFFFB088)
val CatOrangeDark = Color(0xFFE55A2B)

val BrandPurple = Color(0xFF7C3AED)
val BrandPurpleLight = Color(0xFFA78BFA)
val BrandPurpleDark = Color(0xFF5B21B6)

val LostRed = Color(0xFFEF4444)
val LostRedLight = Color(0xFFFCA5A5)
val FoundGreen = Color(0xFF22C55E)
val FoundGreenLight = Color(0xFF86EFAC)
val ReunitedGold = Color(0xFFF59E0B)
val ReunitedGoldLight = Color(0xFFFCD34D)

val CreamBackground = Color(0xFFFFF8F0)
val CardWarm = Color(0xFFFFFBF5)

// Pet-friendly color palette
private val LightColors = lightColorScheme(
    primary = CatOrange,
    onPrimary = Color.White,
    primaryContainer = CatOrangeLight,
    onPrimaryContainer = Color(0xFF7A2800),
    
    secondary = BrandPurple,
    onSecondary = Color.White,
    secondaryContainer = BrandPurpleLight,
    onSecondaryContainer = Color(0xFF3B0764),
    
    tertiary = FoundGreen,
    onTertiary = Color.White,
    tertiaryContainer = FoundGreenLight,
    onTertiaryContainer = Color(0xFF14532D),
    
    error = LostRed,
    errorContainer = LostRedLight,
    
    background = CreamBackground,
    onBackground = Color(0xFF1C1917),
    
    surface = Color.White,
    onSurface = Color(0xFF1C1917),
    surfaceVariant = CardWarm,
    onSurfaceVariant = Color(0xFF6B6B6B),
    
    outline = Color(0xFFDDDDDD),
    outlineVariant = Color(0xFFEEEEEE),
)

private val DarkColors = darkColorScheme(
    primary = CatOrange,
    onPrimary = Color.White,
    primaryContainer = CatOrangeDark,
    onPrimaryContainer = CatOrangeLight,
    
    secondary = BrandPurpleLight,
    onSecondary = Color.White,
    secondaryContainer = BrandPurpleDark,
    onSecondaryContainer = BrandPurpleLight,
    
    tertiary = FoundGreen,
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFF166534),
    onTertiaryContainer = FoundGreenLight,
    
    error = LostRedLight,
    errorContainer = Color(0xFF7F1D1D),
    
    background = Color(0xFF1C1917),
    onBackground = Color(0xFFFAFAFA),
    
    surface = Color(0xFF2C2C2C),
    onSurface = Color(0xFFFAFAFA),
    surfaceVariant = Color(0xFF3C3C3C),
    onSurfaceVariant = Color(0xFFAAAAAA),
    
    outline = Color(0xFF555555),
    outlineVariant = Color(0xFF444444),
)

@Composable
fun PawsomeTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) DarkColors else LightColors,
        content = content,
    )
}
