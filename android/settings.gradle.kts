import java.util.Properties
import java.io.File

pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties() // Use fully qualified name
        val localPropertiesFile = File(rootDir, "local.properties")
        if (localPropertiesFile.exists()) {
            localPropertiesFile.inputStream().use { stream ->
                properties.load(stream)
            }
        }
        val sdkPath = properties.getProperty("flutter.sdk")
        checkNotNull(sdkPath) { "flutter.sdk not set in local.properties. This file should be in the 'android' directory and contain a line like 'flutter.sdk=C:\\path\\to\\your\\flutter\\sdk'" }
        sdkPath
    }
    // Pass the path as a String directly to includeBuild
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false // Check for the latest/appropriate version
}

include(":app")
