# Keep rules for release builds (isMinifyEnabled = true in build.gradle.kts).
#
# ⚠️ WHY THIS FILE MATTERS NOW: with minification ON and this file
# previously empty, R8 was free to strip/rename classes that Cashfree's SDK
# (and others) reach via reflection — which can make the SDK fail silently
# at runtime in a release build even though it works fine in debug. This is
# a second, independent possible cause of the Cashfree checkout closing
# immediately, alongside the debug-signing issue.

# ---------------- Cashfree Payment Gateway SDK ----------------
-keep class com.cashfree.pg.** { *; }
-keep interface com.cashfree.pg.** { *; }
-dontwarn com.cashfree.pg.**

# ---------------- Firebase (Messaging / Core) ----------------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ---------------- OneSignal ----------------
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**

# ---------------- Google Play Services (used by google_sign_in, FCM, etc) ----------------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ---------------- General: keep annotations & native methods ----------------
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
-keepclasseswithmembernames class * {
    native <methods>;
}

# ---------------- Gson / JSON models some SDKs bundle ----------------
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}