# Keep Flutter classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep flutter_background_service classes
-keep class com.pravera.flutter_background_service.** { *; }
-dontwarn com.pravera.flutter_background_service.**

# Keep Geolocator classes
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Keep Google Play services classes
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Prevent R8/ProGuard from stripping interfaces and annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod