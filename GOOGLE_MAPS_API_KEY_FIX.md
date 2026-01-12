# Google Maps API Key Fix

## Issue

The app was crashing when opening the Nearby Places screen with two errors:

1. **Missing Google Maps API Key:**
   ```
   API key not found. Check that <meta-data android:name="com.google.android.geo.API_KEY" 
   android:value="your API key"/> is in the <application> element of AndroidManifest.xml
   ```

2. **Type Casting Error:**
   ```
   Error fetching places for type church: type 'int' is not a subtype of type 'double?' in type cast
   ```

## Solution

### 1. Added Google Maps API Key to AndroidManifest.xml

**File:** `faith_connect/android/app/src/main/AndroidManifest.xml`

**Added:**
```xml
<!-- Google Maps API Key -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyCECVlPxjzB9WVBEnqwAkBcqZbyEvmdPNE"/>
```

**Location:** Inside the `<application>` tag, before the `<activity>` tag.

### 2. Fixed Type Casting in nearby_screen.dart

**File:** `faith_connect/lib/screens/nearby_screen.dart`

**Problem:** The Google Places API sometimes returns latitude/longitude as integers instead of doubles.

**Fix:** Added type checking to handle both int and double types:
```dart
// Handle both int and double types from API
final latValue = location?['lat'];
final lngValue = location?['lng'];
final placeLat = (latValue is double ? latValue : (latValue is int ? latValue.toDouble() : 0.0));
final placeLng = (lngValue is double ? lngValue : (lngValue is int ? lngValue.toDouble() : 0.0));
```

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
   - The map should load with your current location
   - Nearby religious places should appear on the map and in the list

## Note

- The Google Maps API key is required for the `google_maps_flutter` package to work
- This is the same API key used for Google Places API
- Make sure the API key has both Maps SDK for Android and Places API enabled in Google Cloud Console
