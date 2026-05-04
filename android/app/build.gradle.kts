import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val localFile = rootProject.file("local.properties")
    if (localFile.exists()) {
        localFile.inputStream().use { load(it) }
    }
}

val apiKey = (localProperties.getProperty("API_KEY") ?: "").trim()

android {
    namespace = "com.managestress.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        // Modern Kotlin DSL for setting jvmTarget to avoid deprecation warning
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.managestress.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Enforce minimum supported SDKs for AndroidX and Google Play services
        // Flutter requires a minimum of 23 for this project; raise to 23 to pass dependency validation.
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // API_KEY is injected at build time from local.properties.
        // Keep local.properties out of version control so keys are never hardcoded.
        buildConfigField("String", "API_KEY", "\"$apiKey\"")
        manifestPlaceholders["API_KEY"] = apiKey
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Updated AndroidX libs to recent stable versions to reduce compatibility warnings
    implementation("androidx.core:core-ktx:1.18.0")
    implementation("androidx.core:core:1.18.0")
    implementation("androidx.annotation:annotation:1.10.0")
    implementation("androidx.appcompat:appcompat:1.7.1")

    // Google Play services: Auth (Sign-In) and Fitness
    implementation("com.google.android.gms:play-services-auth:20.7.0'")
    implementation("com.google.android.gms:play-services-fitness:21.1.0")
}

flutter {
    source = "../.."
}
