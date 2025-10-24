import java.util.Properties // Import Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    kotlin("android") // Use kotlin("android") instead of id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Read local properties using Kotlin syntax
val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties") // Use double quotes
if (localPropertiesFile.exists()) {
    localPropertiesFile.reader(Charsets.UTF_8).use { reader -> // Use reader with Charsets
        localProperties.load(reader)
    }
}

val flutterVersionCode: String = localProperties.getProperty("flutter.versionCode") ?: "1" // Use double quotes and provide default
val flutterVersionName: String = localProperties.getProperty("flutter.versionName") ?: "1.0" // Use double quotes and provide default

android {
    namespace = "com.example.delivery" // <-- Check your namespace
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // <-- NDK Version correct

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8 // Or your Java version (use _1_8 for Kotlin)
        targetCompatibility = JavaVersion.VERSION_1_8 // Or your Java version
    }

    kotlinOptions {
        jvmTarget = "1.8" // Use string "1.8" for Kotlin
    }

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin") // Kotlin way to add source dir
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.delivery" // <-- Check your Application ID
        minSdk = 23 // <--- Min SDK correct
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt() // Use .toInt()
        versionName = flutterVersionName
        multiDexEnabled = true // <-- Enable MultiDex
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    // Set packaging options if needed, for example:
    // packaging {
    //     resources.excludes.add("/META-INF/{AL2.0,LGPL2.1}")
    // }
}

flutter {
    source = "../.."
}

dependencies {
     implementation(kotlin("stdlib-jdk8")) // Ensure Kotlin stdlib is included
     implementation("androidx.multidex:multidex:2.0.1") // <-- Add MultiDex dependency
    // Add other dependencies here
}