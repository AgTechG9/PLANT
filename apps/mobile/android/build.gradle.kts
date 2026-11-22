allprojects {
    buildscript {
        configurations.all {
            resolutionStrategy {
                force("com.android.tools.build:gradle:9.1.0")
                force("org.jetbrains.kotlin:kotlin-gradle-plugin:2.2.21")
                force("org.jetbrains.kotlin:kotlin-gradle-plugin-api:2.2.21")
            }
        }
    }
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
