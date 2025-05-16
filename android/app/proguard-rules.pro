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



# Flutter
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# flutter_background_service
-keep class com.pravera.flutter_background_service.** { *; }

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# Google Play Services (Maps)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# GetX
-keep class get.** { *; }

# Shared Preferences
-keep class androidx.preference.** { *; }

# Keep annotations
-keepattributes *Annotation*
