# Google ML Kit (Required by mobile_scanner)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Google Play Services (Required for barcode scanner and general camera functions)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Flutter internals (Protects plugin bindings and entrypoints)
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Prevent shrinking of mobile_scanner plugin classes
-keep class dev.steenbakker.mobile_scanner.** { *; }
-dontwarn dev.steenbakker.mobile_scanner.**
