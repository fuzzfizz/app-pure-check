# Flutter deferred components & Play Store split install (Resolves R8 missing class errors)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Flutter internals (Protects plugin bindings and entrypoints)
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit (Required by mobile_scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Services (Required for barcode scanner and general camera functions)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Prevent shrinking of mobile_scanner plugin classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
