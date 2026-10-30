# flutter_local_notifications persists scheduled notifications through Gson
# TypeToken; R8 strips the generic signature and cancel()/loadScheduledNotifications
# throws "Missing type parameter" (seen on every departed-crossing cancel in
# S26 field logs). Keep Gson reflection metadata.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.** { *; }
