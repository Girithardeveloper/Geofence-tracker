# Flutter keep rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# AndroidX Lifecycle
-keep class androidx.lifecycle.** { *; }

# Permission Handler
-keep class com.baseflow.permissionhandler.** { *; }





# Keep annotations
-keepattributes *Annotation*
