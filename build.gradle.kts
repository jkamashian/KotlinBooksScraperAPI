import com.github.jengelman.gradle.plugins.shadow.tasks.ShadowJar
plugins {
    kotlin("jvm") version "1.9.23"
    id("com.github.johnrengelman.shadow") version "7.1.2"
    application
}

group = "org.example"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation("com.amazonaws:aws-lambda-java-core:1.2.2")
    implementation("com.amazonaws:aws-lambda-java-events:3.11.4")
    implementation("org.postgresql:postgresql:42.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.3.2")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.0.1")
    implementation("com.squareup.okhttp3:okhttp:4.9.3")
    implementation("org.jsoup:jsoup:1.16.2")
    testImplementation(kotlin("test"))
}



// Define a ShadowJar task for each Lambda function
tasks.register<ShadowJar>("shadowJarGet") {
    archiveFileName.set("GetFunction-${project.version}.jar")
    from(sourceSets.main.get().output)
    configurations = listOf(project.configurations.runtimeClasspath.get())

    // Set the main class for the specific function
    manifest {
        attributes["Main-Class"] = "get.Handler"
    }
}

tasks.register<ShadowJar>("shadowJarScrape") {
    archiveClassifier.set("scrape")
    archiveFileName.set("ScrapeFunction-${project.version}.jar")
    from(sourceSets.main.get().output)
    configurations = listOf(project.configurations.runtimeClasspath.get())

    // Set the main class for the specific function
    manifest {
        attributes["Main-Class"] = "scrape.Handler"
    }
}

tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}