# Flutter & Android R8 / ProGuard Rules
-dontwarn io.flutter.embedding.**

# Firebase & Reflection Attributes
-keepattributes Signature
-keepattributes *Annotation*

# Keep custom model classes if you use them with Firestore
# e.g. -keep class net.hilmost.ultimatetictactoe.models.** { *; }
