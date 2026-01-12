# Google Places API Setup Guide

## Overview

The Nearby Places screen now searches for all religious places within 10 km using the Google Places API.

## Setup Instructions

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Places API**:

   - Navigate to "APIs & Services" > "Library"
   - Search for "Places API"
   - Click "Enable"

4. Create API Key:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy the API key

### 2. Configure API Key in Code

Open `faith_connect/lib/screens/nearby_screen.dart` and replace:

```dart
static const String _placesApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
```

With your actual API key:

```dart
static const String _placesApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### 3. Restrict API Key (Recommended)

For security, restrict your API key:

1. In Google Cloud Console, go to "Credentials"
2. Click on your API key
3. Under "API restrictions", select "Restrict key"
4. Choose "Places API" only
5. Under "Application restrictions", add your app's package name for Android/iOS

### 4. Features Implemented

- ✅ Searches for multiple religious place types:

  - Churches
  - Mosques
  - Synagogues
  - Hindu Temples
  - General Places of Worship

- ✅ 10 km radius search (10,000 meters)

- ✅ Displays places on Google Maps with markers

- ✅ Shows place list with:

  - Name
  - Type
  - Distance
  - Address (if available)
  - Rating (if available)

- ✅ Sorts places by distance (nearest first)

- ✅ Calculates distance from user's location

### 5. API Limits

- Free tier: $200 credit per month
- Each Nearby Search request costs approximately $0.032
- With free tier, you can make ~6,250 requests per month

### 6. Testing

Once configured:

1. Open the Nearby Places screen
2. Grant location permissions
3. The app will automatically search for religious places within 10 km
4. Places will appear on the map and in the list below

### 7. Optional: Add Directions

To enable directions functionality, add `url_launcher` package:

```yaml
dependencies:
  url_launcher: ^6.2.2
```

Then update the directions button handler in `nearby_screen.dart`:

```dart
import 'package:url_launcher/url_launcher.dart';

// In the directions button onPressed:
final lat = place['latitude'] as double;
final lng = place['longitude'] as double;
final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
if (await canLaunchUrl(Uri.parse(url))) {
  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}
```

## Notes

- The API key is stored in the code. For production, consider using environment variables or secure storage.
- The app searches for all religious place types simultaneously and combines results.
- Results are deduplicated using place_id to avoid showing the same place multiple times.
