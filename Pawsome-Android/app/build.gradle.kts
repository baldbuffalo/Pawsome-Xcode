plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.pawsome.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.pawsome.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Baked from CI secrets. GOOGLE_SERVER_CLIENT_ID is the Web OAuth client id
        // (serverClientId) used by Credential Manager; the app's signing SHA-1 must
        // be registered in an Android OAuth client in the same project.
        fun env(name: String) = System.getenv(name)?.ifBlank { null } ?: ""
        buildConfigField("String", "GOOGLE_SERVER_CLIENT_ID", "\"${env("ANDROID_GOOGLE_WEB_CLIENT_ID")}\"")
        buildConfigField("String", "TWITTER_CONSUMER_KEY", "\"${env("TWITTER_CONSUMER_KEY")}\"")
        buildConfigField("String", "TWITTER_CONSUMER_SECRET", "\"${env("TWITTER_CONSUMER_SECRET")}\"")
        buildConfigField("String", "GITHUB_TOKEN", "\"${env("PAWSOME_GITHUB_TOKEN")}\"")
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.14"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    signingConfigs {
        create("release") {
            System.getenv("ANDROID_KEYSTORE_FILE")?.let {
                storeFile = file(it)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            if (System.getenv("ANDROID_KEYSTORE_FILE") != null)
                signingConfig = signingConfigs.getByName("release")
        }
    }
    packaging {
        resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.2")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.2")
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
    implementation("io.coil-kt:coil-compose:2.6.0")
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
}
