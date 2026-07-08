import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val releaseManifestPermissionsToStrip = listOf(
    "com.google.android.gms.permission.AD_ID",
    "android.permission.ACCESS_ADSERVICES_AD_ID",
    "android.permission.ACCESS_ADSERVICES_ATTRIBUTION",
)

android {
    namespace = "com.zabnix.shield"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.zabnix.shield"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

val stripReleaseAdIdPermissions by tasks.registering {
    dependsOn("processReleaseManifestForPackage")

    val packagedManifest = layout.buildDirectory.file(
        "intermediates/packaged_manifests/release/processReleaseManifestForPackage/AndroidManifest.xml",
    )

    inputs.file(packagedManifest)
    outputs.file(packagedManifest)

    doLast {
        val manifestFile = packagedManifest.get().asFile
        if (!manifestFile.exists()) {
            throw GradleException("Packaged release manifest not found at ${manifestFile.absolutePath}")
        }

        var manifestText = manifestFile.readText()
        releaseManifestPermissionsToStrip.forEach { permission ->
            manifestText = manifestText.replace(
                Regex("""\s*<uses-permission android:name="$permission"\s*/>\r?\n"""),
                "",
            )
        }

        manifestFile.writeText(manifestText)
    }
}

tasks.matching {
    it.name in setOf(
        "assembleRelease",
        "bundleRelease",
        "packageReleaseBundle",
        "processReleaseResources",
    )
}.configureEach {
    dependsOn(stripReleaseAdIdPermissions)
}
