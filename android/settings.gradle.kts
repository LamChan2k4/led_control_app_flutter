// Vị trí: android/settings.gradle.kts

// --- BẮT ĐẦU KHỐI LỆNH PLUGINMANAGEMENT (Chạy đầu tiên) ---
pluginManagement {
    // Đọc đường dẫn SDK trực tiếp bên trong khối lệnh này để đảm bảo an toàn.
    val properties = java.util.Properties()
    val localPropertiesFile = java.io.File(settings.rootDir, "local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use(properties::load)
    }
    val sdkPath = properties.getProperty("flutter.sdk")
    require(sdkPath != null) { "flutter.sdk not set in local.properties" }

    // Sử dụng đường dẫn vừa lấy được
    includeBuild(sdkPath + "/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
// --- KẾT THÚC KHỐI LỆNH PLUGINMANAGEMENT ---


// --- BẮT ĐẦU KHỐI LỆNH CHÍNH (Chạy sau) ---

// SỬA LỖI Ở ĐÂY: Áp dụng các plugin theo cách mới, "khai báo".
plugins {
    // Plugin này sẽ tự động tải JDK 17 cho bạn.
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"

    // SỬA LỖI: Đây là cách mới để tải các plugin của Flutter, thay thế cho `apply(from=...)`.
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Các plugin cần thiết khác cho dự án Flutter.
    id("com.android.application").version("8.7.3").apply(false)
    id("org.jetbrains.kotlin.android").version("2.1.0").apply(false)
}

include(":app")

// SỬA LỖI: XÓA BỎ HOÀN TOÀN các dòng lệnh cũ ở đây.
// Không cần đọc lại properties.
// Không cần dùng `apply(from=...)` nữa.