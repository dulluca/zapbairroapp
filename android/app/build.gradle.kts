import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties().apply {
    if (hasKeystore) {
        load(FileInputStream(keystorePropertiesFile))
    }
}

android {
    namespace = "com.zapbairro"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.zapbairro.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        // Vem do pubspec.yaml (version: 1.1.0+8 -> versionName 1.1.0,
        // versionCode 8). Fixo aqui, o numero do pubspec era ignorado e a
        // Play Store recusava o pacote por codigo de versao repetido.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Novo DSL para Kotlin
    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }

    signingConfigs {
        if (hasKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            // Assina com a chave de release quando key.properties existir;
            // caso contrário usa a chave de debug para permitir builds locais.
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
        getByName("debug") {
            // usa a chave de debug padrão
        }
    }
}

flutter {
    source = "../.."
}

