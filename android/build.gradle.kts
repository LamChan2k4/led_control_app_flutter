// Vị trí: android/build.gradle.kts

buildscript {
    val kotlinVersion = "1.9.23"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.2.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

// Giữ lại khối này để đảm bảo các kho chứa có sẵn cho tất cả module.
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Giữ lại khối này để sửa lỗi không nhất quán JVM.
subprojects {
    afterEvaluate {
        plugins.withType<com.android.build.gradle.BasePlugin>().configureEach {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }
            }
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "17"
            }
        }
    }
}

// THÊM VÀO ĐÂY: Cách thay đổi thư mục build một cách chính xác
// Đoạn mã này sẽ đặt thư mục build của toàn bộ dự án Android
// vào thư mục 'build' ở cấp cao nhất của dự án Flutter.
// Đây là hành vi mặc định và được khuyến nghị.
allprojects {
    // `project.buildDir` chỉ định thư mục build cho từng module con.
    // Chúng ta sẽ đặt nó vào bên trong thư mục `build` chung của toàn dự án.
    buildDir = rootProject.layout.buildDirectory.dir(project.name).get().asFile
}