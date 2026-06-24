# WorkManager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}
-keep interface androidx.work.** { *; }
-dontwarn androidx.work.**

# Flutter local notifications
-keep class com.dexterous.** { *; }
