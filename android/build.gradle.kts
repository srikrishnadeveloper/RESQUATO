buildscript {
    // Allow Flutter tool to override Kotlin version, otherwise default to a recent stable version.
    val kotlinVersion = System.getProperty("kotlinVersion") ?: "1.9.23"
    // Make kotlinVersion available as 'ext.kotlin_version' for Groovy scripts (like app/build.gradle)
    extra.set("kotlin_version", kotlinVersion)

    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Use a recent stable AGP version. Ensure this is compatible with your Gradle version.
        classpath("com.android.tools.build:gradle:8.2.0") 
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${kotlinVersion}")
        // Ensure this Google Services plugin version is compatible.
        classpath("com.google.gms:google-services:4.4.2")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Remove explicit rootProject.buildDir setting, Flutter plugin typically handles this.
// rootProject.buildDir = File("../build") // Deprecated and potentially conflicting

// The default 'clean' task provided by Gradle should be sufficient.
// If you need a custom clean, use modern APIs, but often not needed here.
// tasks.register<Delete>("clean") {
//     delete(rootProject.buildDir) // buildDir usage here is also deprecated
// }
// It's generally safer to rely on the clean task provided by the Android Gradle Plugin
// for the app module and the Flutter plugin for Flutter-specific artifacts.
// Running `./gradlew clean` in the android directory will trigger AGP's clean.
// Running `flutter clean` handles Flutter's build artifacts.
