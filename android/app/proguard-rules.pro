# Flutter defaults
-dontwarn io.flutter.embedding.**
-keep class io.flutter.plugins.** { *; }

# Dio + JSON reflection safety
-keep class ** implements java.io.Serializable { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep our model classes (adjust package if you move models)
-keep class com.ejack.ejack.models.** { *; }
