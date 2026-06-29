import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// Parse --dart-define / --dart-define-from-file values forwarded by Flutter.
// Flutter base64-encodes each key=value pair, comma-separated, as 'dart-defines'.
val dartDefines = mutableMapOf<String, String>()
if (project.hasProperty("dart-defines")) {
    (project.property("dart-defines") as String).split(",").forEach { encoded ->
        val decoded = String(Base64.getDecoder().decode(encoded)).trim()
        val idx = decoded.indexOf('=')
        if (idx > 0) dartDefines[decoded.substring(0, idx)] = decoded.substring(idx + 1)
    }
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}

android {
    namespace = "com.appsbay.simple_calculator"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.appsbay.simple_calculator"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // AdMob App ID — injected from --dart-define-from-file=ad_ids.release.json for release
        // builds; falls back to Google's official test App ID for debug/profile runs.
        manifestPlaceholders["admobAppId"] = dartDefines.getOrDefault(
            "ADMOB_APP_ID_ANDROID",
            "ca-app-pub-3940256099942544~3347511713"
        )
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = if (keystoreProperties["storeFile"] != null)
                file(keystoreProperties["storeFile"] as String) else null
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

