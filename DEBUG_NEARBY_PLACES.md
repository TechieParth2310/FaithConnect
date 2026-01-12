# Debugging Nearby Places Search

## Issue

The app shows "No religious places found within 10 km" even though there are temples and mosques nearby.

## Possible Causes

1. **API Key Restrictions**: The API key might be restricted and not allowing Places API calls
2. **API Not Enabled**: Places API might not be enabled for the API key
3. **Billing Issues**: Google Cloud billing might not be set up
4. **API Quota Exceeded**: Daily quota might be exceeded
5. **API Response Errors**: The API might be returning errors that we're not displaying

## Debugging Steps Added

I've added debug logging to help identify the issue:

1. **API Response Status Logging**: Now logs the API response status for each place type
2. **Error Message Logging**: Logs detailed error messages from the API
3. **Place Count Logging**: Logs how many places are found for each type
4. **Total Places Logging**: Logs the total number of places found

## How to Debug

1. **Run the app with debug output:**
   ```bash
   cd faith_connect
   flutter run
   ```

2. **Open the Nearby Places screen** and check the console/logcat output

3. **Look for these log messages:**
   - `🔍 Places API Response for [type]: [status]` - Shows API response status
   - `✅ Found X places of type [type]` - Shows how many places were found
   - `❌ Places API Error: [status] - [message]` - Shows API errors
   - `📍 Total places found: X` - Shows total places after combining all types

## Common API Errors

- **REQUEST_DENIED**: API key is invalid or restricted
- **OVER_QUERY_LIMIT**: Quota exceeded
- **INVALID_REQUEST**: Bad request parameters
- **UNKNOWN_ERROR**: Server error

## Fixing the Issue

### 1. Enable Places API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Go to "APIs & Services" > "Library"
4. Search for "Places API"
5. Click "Enable"

### 2. Check API Key Restrictions

1. Go to "APIs & Services" > "Credentials"
2. Click on your API key
3. Under "API restrictions":
   - Either select "Don't restrict key" (for testing)
   - Or select "Restrict key" and add "Places API" to the allowed APIs
4. Under "Application restrictions":
   - For Android, add your package name: `com.faithconnect.app`
   - Add your SHA-1 fingerprint (get it with: `./gradlew signingReport`)

### 3. Check Billing

1. Go to "Billing" in Google Cloud Console
2. Make sure billing is enabled
3. Places API requires billing to be enabled

### 4. Check Quota

1. Go to "APIs & Services" > "Dashboard"
2. Select "Places API"
3. Check your quota usage

## Testing the API Key Directly

You can test the API key with a direct HTTP request:

```bash
curl "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=28.6139,77.2090&radius=10000&type=place_of_worship&key=AIzaSyCECVlPxjzB9WVBEnqwAkBcqZbyEvmdPNE"
```

Replace the location coordinates with your current location (latitude,longitude).

Expected response:
- **OK**: Places found successfully
- **ZERO_RESULTS**: No places found (might be normal)
- **REQUEST_DENIED**: API key issue
- **OVER_QUERY_LIMIT**: Quota exceeded

## Next Steps

1. Run the app and check the debug logs
2. Share the log output to identify the specific issue
3. Fix the API key configuration based on the error message
