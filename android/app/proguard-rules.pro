# Flutter's default rules.
#
# See https://flutter.dev/docs/deployment/android#enabling-r8 for more information.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Firebase SDK specific rules
# See https://firebase.google.com/docs/android/setup#add-sdk
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.firebase.** { *; }
-keep class org.json.** { *; }

# Keep custom model classes if you use them with Firestore
# e.g. -keep class net.hilmost.ultimatetictactoe.models.** { *; }
