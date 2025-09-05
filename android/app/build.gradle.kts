plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "lol.arian.notifmirror"
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "lol.arian.notifmirror"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    applicationVariants.configureEach {
        val appName = "NotifMirror"

        // Use mergedFlavor for compatibility across AGP versions
        val vName = mergedFlavor.versionName ?: defaultConfig.versionName
        val vCode = mergedFlavor.versionCode ?: defaultConfig.versionCode

        outputs.configureEach {
            val output = this as com.android.build.gradle.internal.api.BaseVariantOutputImpl
            // ABI filter: arm64-v8a, armeabi-v7a, etc.
            val abiFilter = output.getFilter(com.android.build.OutputFile.ABI) ?: "universal"

            // In Kotlin DSL, assign directly via the internal API
            output.outputFileName = "${appName}-v${vName}(${vCode})-${abiFilter}.apk"
        }
    }
}

flutter {
    source = "../.."
}
