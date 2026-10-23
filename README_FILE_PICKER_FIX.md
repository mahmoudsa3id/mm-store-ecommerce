# File Picker / AGP 9 Fix

This final project pins `file_picker: 12.3.0`.

`file_picker` 12 moved to the federated architecture, and the 12.x Android implementation includes the AGP 9 compatibility fixes. The app code uses the 12.x API (`FilePicker.pickFile()` and `PlatformFile.readAsBytes()`).

After extracting the project:

```bash
flutter clean
flutter pub get
flutter run --flavor customer -t lib/main.dart
flutter run --flavor admin -t lib/main_admin.dart
```

Do not commit `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java`; Flutter regenerates that file during plugin registration.
