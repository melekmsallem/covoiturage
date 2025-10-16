plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")         // Kotlin Android plugin
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")       // Google services plugin (for google-services.json)
}

android {
    namespace = "com.covoiturage.covoiturage_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Make sure this matches the package you registered in Firebase Console (Android app)
        applicationId = "com.covoiturage.covoiturage_app"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: replace with your real keystore for production
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        debug {
            isShrinkResources = false
            // Keep default debug config
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BOM manages consistent versions for all Firebase libs
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))

    // Firebase Auth for Phone Authentication
    implementation("com.google.firebase:firebase-auth")
}