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
    pluginManager.withPlugin("com.android.library") {
        // 注意：这里的 this 是 AppliedPlugin，需要用 project 引用当前项目
        val androidExt = project.extensions.findByName("android")
        if (androidExt != null) {
            try {
                val namespaceProp = androidExt.javaClass.getMethod("getNamespace")
                val currentNamespace = namespaceProp.invoke(androidExt)
                if (currentNamespace == null) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val content = manifestFile.readText()
                        val match = Regex("""package="([^"]+)"""").find(content)
                        if (match != null) {
                            val setNamespace = androidExt.javaClass.getMethod("setNamespace", String::class.java)
                            setNamespace.invoke(androidExt, match.groupValues[1])
                        }
                    }
                }
            } catch (e: Exception) {
                // 忽略异常，防止阻断编译
            }
        }
    }
}