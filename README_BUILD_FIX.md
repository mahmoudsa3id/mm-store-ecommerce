# Build / Flavor Fix

## Customer Android
flutter clean
flutter pub get
flutter run --flavor customer -t lib/main.dart

## Admin Android
flutter clean
flutter pub get
flutter run --flavor admin -t lib/main_admin.dart

Do not run the Android `assembleDebug` task directly for the Admin flavor. Use the Flutter command above so Flutter selects `adminDebug` and can locate the generated APK.

The Android root build.gradle.kts intentionally uses Flutter/Gradle's default build directory so Flutter can locate generated APKs.
