plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    aaptOptions {
        noCompress += "mp3"
    }

    namespace = "com.example.cross_aware"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.cross_aware"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Foreground service receiver patch (final AGP 8.7 compatible)
    applicationVariants.all {
        outputs.forEach {
            it.processManifestProvider.configure {
                doLast {
                    // Access merged manifest directory
                    val manifestDir = outputs.files.firstOrNull()
                    val manifestFile = manifestDir?.resolve("AndroidManifest.xml")

                    if (manifestFile != null && manifestFile.exists()) {
                        var content = manifestFile.readText()

                        if (content.contains("com.pravera.flutter_foreground_task.receiver")) {
                            println("🔧 Fixing ForegroundTask receivers in merged manifest...")

                            content = content
                                .replace(
                                    "<receiver android:name=\"com.pravera.flutter_foreground_task.receiver.ForegroundServiceReceiver\"",
                                    "<receiver android:name=\"com.pravera.flutter_foreground_task.receiver.ForegroundServiceReceiver\" android:exported=\"false\""
                                )
                                .replace(
                                    "<receiver android:name=\"com.pravera.flutter_foreground_task.receiver.RestartReceiver\"",
                                    "<receiver android:name=\"com.pravera.flutter_foreground_task.receiver.RestartReceiver\" android:exported=\"false\""
                                )

                            manifestFile.writeText(content)
                        }
                    }
                }
            }
        }
    }

}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
