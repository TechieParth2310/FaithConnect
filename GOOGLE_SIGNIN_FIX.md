# 🔧 Google Sign-In Fix Guide for Android

## ❌ **The Error You're Seeing:**
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.Api10:, null, null)
```

This error occurs because Google Sign-In requires your app's **SHA-1 fingerprint** to be registered in Firebase Console.

---

## ✅ **Step-by-Step Fix:**

### **Step 1: Get Your SHA-1 Fingerprint**

Run this command in your terminal:

```bash
cd /Users/parthkothawade/Downloads/Projects/FaithConnectHackathon/faith_connect/android
./gradlew signingReport
```

Look for the output that shows:
```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
SHA1: [YOUR_SHA1_FINGERPRINT_HERE]
```

**Copy the SHA-1 fingerprint** (it looks like: `A1:B2:C3:D4:E5:F6:...`)

### **Step 2: Add SHA-1 to Firebase Console**

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **faithconnect-fe032**
3. Click the ⚙️ **Settings icon** (top left) → **Project settings**
4. Scroll down to **Your apps** section
5. Find your **Android app** (`com.faithconnect.app`)
6. Click on it to expand
7. Scroll down to **SHA certificate fingerprints**
8. Click **"Add fingerprint"**
9. Paste your **SHA-1 fingerprint**
10. Click **Save**

### **Step 3: Enable Google Sign-In in Firebase**

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Find **Google** in the list
3. Click on it
4. Toggle **Enable** (make sure it's ON)
5. Enter **Support email** (your email)
6. Click **Save**

### **Step 4: Wait & Rebuild**

- Wait **2-5 minutes** for Firebase to process the changes
- Rebuild your app:
  ```bash
  cd /Users/parthkothawade/Downloads/Projects/FaithConnectHackathon/faith_connect
  flutter clean
  flutter pub get
  flutter run
  ```

---

## 🔍 **Alternative: Get SHA-1 Using Keytool**

If `./gradlew signingReport` doesn't work, use this command:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the **SHA1:** line and copy that value.

---

## 📝 **Important Notes:**

1. **For Release Builds:** You'll need to add your **release keystore's SHA-1** too (when you create a release keystore)

2. **Package Name Must Match:** Make sure your package name in Firebase Console is exactly `com.faithconnect.app`

3. **OAuth Consent Screen:** Firebase automatically handles OAuth consent, but if you get consent screen errors, check Firebase Console → Authentication → Settings → Authorized domains

4. **Wait Time:** After adding SHA-1, wait a few minutes before testing. Firebase needs time to propagate the changes.

---

## ✅ **After Fixing:**

Once you've completed these steps:
- ✅ Google Sign-In button will work
- ✅ Users can sign in with their Google account
- ✅ User profile will be created automatically in Firestore

---

## 🐛 **If Still Not Working:**

1. Double-check the SHA-1 fingerprint matches exactly (no extra spaces)
2. Verify Google Sign-In is enabled in Firebase Console
3. Check that package name matches: `com.faithconnect.app`
4. Try uninstalling and reinstalling the app on your device
5. Check Firebase Console logs for any errors

---

## 📱 **Testing:**

After fixing, test Google Sign-In:
1. Open the app
2. Go to Sign In screen
3. Click "Continue with Google"
4. Select your Google account
5. Grant permissions
6. ✅ Should sign in successfully!
