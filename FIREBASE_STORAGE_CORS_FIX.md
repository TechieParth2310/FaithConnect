# Firebase Storage CORS Configuration

## Problem

Images uploaded to Firebase Storage are not displaying in the web app. This is typically due to CORS (Cross-Origin Resource Sharing) restrictions.

## Solution

### Option 1: Configure CORS via Firebase Console (Recommended for Production)

1. Go to Firebase Console → Storage → Rules
2. Update the rules to allow read access:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;  // Allow public read access
      allow write: if request.auth != null;  // Only authenticated users can write
    }
  }
}
```

### Option 2: Configure CORS via gsutil (For Development)

If you have Google Cloud SDK installed:

1. Create a `cors.json` file:

```json
[
  {
    "origin": ["http://localhost:8080", "http://localhost:*"],
    "method": ["GET", "HEAD", "PUT", "POST", "DELETE"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

2. Run the following command (replace `YOUR-PROJECT-ID` with your Firebase project ID):

```bash
gsutil cors set cors.json gs://YOUR-PROJECT-ID.appspot.com
```

### Option 3: Quick Fix - Use Firebase Storage Download Tokens

The uploaded images should automatically get download tokens. If images are still not showing, it might be a timing issue.

### Current Workaround Applied

The app now shows:

- A loading spinner while the image is loading
- A clear error message if the image fails to load
- Console logs to help debug the issue

## How to Verify

1. After uploading an image, check the browser console for any error messages
2. Look for the "Image URL" log to see the full Firebase Storage URL
3. Try opening that URL directly in a new browser tab to see if it loads

## Firebase Storage Security Rules

Make sure your Firebase Storage rules allow read access:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      // Allow read access to all
      allow read: if true;

      // Allow write for authenticated users only
      allow write: if request.auth != null;
    }
  }
}
```

To update the rules:

1. Go to Firebase Console
2. Click on Storage
3. Click on "Rules" tab
4. Update the rules as shown above
5. Click "Publish"

## Testing

After applying the fix:

1. Hot reload the app (press 'r' in terminal)
2. Try uploading a new image
3. Check if the image displays correctly
4. Check browser console for any errors
