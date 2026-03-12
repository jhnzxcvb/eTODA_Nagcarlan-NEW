allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Ensure the build directory is configured correctly for Flutter
val rootBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(rootBuildDir)

subprojects {
    val subProjectBuildDir = rootBuildDir.dir(project.name)
    project.layout.buildDirectory.value(subProjectBuildDir)
}

subprojects {
    if (project.path != ":app") {
        evaluationDependsOn(":app")
    }

    // Force all Android modules to use Java 17 to fix obsolete source value 8 warnings
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin> {
        project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
