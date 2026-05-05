allprojects {
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

subprojects {
    plugins.withId("com.android.library") {
        if (project.name == "mediapipe_task_vision") {
            val android = project.extensions.getByName("android")
            try {
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                setNamespace.invoke(android, "org.tensorflow.mediapipe.task.mediapipe_task_vision")
            } catch (e: Exception) {
                // Ignore
            }
        }
    }
}
