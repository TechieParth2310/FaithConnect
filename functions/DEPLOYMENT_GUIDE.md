# Firebase Cloud Functions Deployment Guide

This guide explains how to deploy the Firebase Cloud Functions for FaithConnect push notifications.

## Prerequisites

1. **Firebase CLI** installed globally:

   ```bash
   npm install -g firebase-tools
   ```

2. **Node.js 18+** installed on your machine

3. **Firebase Blaze Plan** (Pay-as-you-go) - Required for Cloud Functions

## Setup Steps

### 1. Login to Firebase

```bash
firebase login
```

### 2. Get Your Firebase Project ID

Go to [Firebase Console](https://console.firebase.google.com/) and get your project ID.

### 3. Update Configuration

Edit the `.firebaserc` file and replace `YOUR_FIREBASE_PROJECT_ID` with your actual project ID:

```json
{
  "projects": {
    "default": "your-actual-project-id"
  }
}
```

### 4. Navigate to Functions Directory

```bash
cd /Users/parthkothawade/Downloads/Projects/FaithConnectHackathon/functions
```

### 5. Install Dependencies

```bash
npm install
```

### 6. Deploy Functions

```bash
firebase deploy --only functions
```

## Functions Overview

### 1. `sendPushNotification`

- **Trigger**: When a new document is created in `push_notifications` collection
- **Action**: Sends FCM push notification to all user's registered devices
- **Features**:
  - Automatic invalid token cleanup
  - Supports Android and iOS
  - Tracks delivery status

### 2. `cleanupOldNotifications`

- **Trigger**: Runs every 24 hours (scheduled)
- **Action**: Deletes push notification records older than 7 days

### 3. `sendTopicNotification`

- **Trigger**: HTTP callable function
- **Action**: Sends broadcast notifications to topic subscribers

## How It Works

1. When a user performs an action (like, comment, follow, etc.) in the app
2. The app creates a document in the `push_notifications` collection
3. The Cloud Function automatically triggers
4. It fetches the target user's FCM tokens from their profile
5. Sends the push notification to all their registered devices
6. Updates the notification document with delivery status

## Testing

### Local Testing

```bash
firebase emulators:start --only functions
```

### View Logs

```bash
firebase functions:log
```

## Firestore Structure

### `push_notifications` Collection

```javascript
{
  userId: "user123",          // Target user ID
  title: "John liked your post",
  body: "Check it out!",
  type: "like",               // like, comment, newFollower, newMessage, newPost, newReel
  postId: "post123",          // Optional
  chatId: "chat456",          // Optional
  imageUrl: "https://...",    // Optional
  createdAt: Timestamp,
  sent: false,                // Updated by function
  sentAt: Timestamp,          // Set by function
  successCount: 2,            // Set by function
  totalTokens: 3              // Set by function
}
```

### `users` Collection (FCM tokens)

```javascript
{
  // ... other user fields
  fcmTokens: ["token1", "token2", "token3"],  // Array of device tokens
  lastTokenUpdate: Timestamp
}
```

## Troubleshooting

### "Permission denied" error

- Make sure Firestore security rules allow the function to read/write
- Ensure your Firebase project is on the Blaze plan

### Notifications not received

1. Check if FCM tokens are being saved to user profiles
2. Check Cloud Functions logs for errors
3. Verify the device has notification permissions enabled
4. Make sure the app is properly registered with FCM

### Invalid tokens

- The function automatically removes invalid tokens
- Tokens become invalid when users uninstall the app or clear data

## Cost Considerations

Firebase Cloud Functions pricing:

- **Free tier**: 2 million invocations/month
- **Blaze plan**: $0.40 per million invocations after free tier

For a small to medium app, this should stay within the free tier.

## Security Rules

Add these Firestore rules to allow the function to operate:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to create push notifications
    match /push_notifications/{notificationId} {
      allow create: if request.auth != null;
      allow read, update, delete: if false; // Only Cloud Functions can read/update
    }
  }
}
```

## Need Help?

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [FCM Documentation](https://firebase.google.com/docs/cloud-messaging)
