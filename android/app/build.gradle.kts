plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.youtube2"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.youtube2"
        minSdk = 24
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["applicationName"] = "io.flutter.app.FlutterApplication"
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
            keepDebugSymbols += listOf("**/*.zip.so", "**/libpython.zip.so", "**/libffmpeg.zip.so")
        }
        resources {
            pickFirsts += listOf(
                "**/libc++_shared.so",
                "**/libavcodec.so",
                "**/libavdevice.so",
                "**/libavfilter.so",
                "**/libavformat.so",
                "**/libavutil.so",
                "**/libswresample.so",
                "**/libswscale.so"
            )
        }
    }

    buildTypes {
        release {
            // Sign with debug keystore for sideloading/testing on a physical device.
            // Replace with a proper signing config before publishing to the Play Store.
            signingConfig = signingConfigs.getByName("debug")

            // Enable R8 code shrinking and resource shrinking for a smaller release APK.
            // The proguard-rules.pro file keeps all required FFmpegKit, OkHttp, Flutter,
            // and plugin classes so they are not incorrectly stripped by R8.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
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

dependencies {
    implementation("io.github.junkfood02.youtubedl-android:library:0.18.1")
    implementation("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
}
