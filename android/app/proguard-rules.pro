# Flutter's default rules.
-dontwarn io.flutter.embedding.**
-keep class io.flutter.embedding.android.FlutterActivity
-keep class io.flutter.embedding.android.FlutterFragment
-keep class io.flutter.embedding.android.FlutterView
-keep class io.flutter.embedding.engine.FlutterJNI

# GIẢI PHÁP CHO LỖI R8 CỦA BẠN
# Các quy tắc này giữ lại các lớp của Google Play Core mà R8 đã xóa nhầm.
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**