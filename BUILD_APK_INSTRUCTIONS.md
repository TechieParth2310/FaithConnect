# Building Release APK

## Quick Build Command

Run this command in your terminal:

```bash
cd faith_connect
flutter build apk --release
```

## APK Location

After building, the APK will be located at:

```
faith_connect/build/app/outputs/flutter-apk/app-release.apk
```

## Alternative: Build Split APKs (Smaller Size)

If you want to build split APKs for different architectures (smaller file size):

```bash
cd faith_connect
flutter build apk --split-per-abi --release
```

This will create:
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM) ← Use this for most modern devices
- `app-x86_64-release.apk` (64-bit x86)

## Install APK on Device

1. **Transfer APK to your device:**
   - Use USB: `adb install build/app/outputs/flutter-apk/app-release.apk`
   - Or copy the APK file to your device and install manually

2. **Enable "Install from Unknown Sources"** on your Android device if needed

## Build App Bundle (For Play Store)

If you want to build for Google Play Store:

```bash
cd faith_connect
flutter build appbundle --release
```

This creates: `build/app/outputs/bundle/release/app-release.aab`

## Notes

- Release APK is optimized and signed (if you have signing configured)
- Debug APK is larger and not optimized
- Make sure all dependencies are up to date: `flutter pub get`
