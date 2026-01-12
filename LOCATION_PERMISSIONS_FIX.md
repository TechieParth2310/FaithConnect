# Location Permissions Fix

## Issue

The Nearby Places screen was showing an error:
```
Error getting location: No location permissions are defined in the manifest. 
Make sure at least ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION are defined in the manifest.
```

## Solution

Added location permissions to the Android manifest file:

**File:** `faith_connect/android/app/src/main/AndroidManifest.xml`

**Added permissions:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
```

## What These Permissions Do

- **ACCESS_FINE_LOCATION**: Allows the app to access precise location (GPS)
- **ACCESS_COARSE_LOCATION**: Allows the app to access approximate location (network-based)

The app will request these permissions at runtime (Android 6.0+) when the user opens the Nearby Places screen.

## Next Steps

1. **Clean and rebuild the app:**
   ```bash
   cd faith_connect
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test the Nearby Places feature:**
   - Open the Nearby Places screen
   - Allow location permissions when prompted
   - The map should now load with your current location and nearby religious places

## Note

- On Android 6.0 (API level 23) and higher, these permissions must be requested at runtime
- The `geolocator` package handles runtime permission requests automatically
- Make sure to grant location permissions when the app requests them
