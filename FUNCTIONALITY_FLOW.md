# 🔄 FaithConnect - Complete Functionality Flow

Step-by-step process flow for every feature and screen in the app.

---

## 🚀 **App Launch Flow**

### **1. Splash Screen**
```
App Starts → Splash Screen (3 seconds)
├── Check Firebase initialization
├── Check authentication status
└── Navigate to:
    ├── Landing Screen (if not authenticated)
    └── Main Wrapper (if authenticated)
```

**Technical Details:**
- Firebase initialization check
- Auth state verification
- Smooth transition animation

---

## 🔐 **Authentication Flow**

### **2. Landing Screen**
```
Landing Screen → User sees:
├── App logo and branding
├── "Get Started" button
└── Navigate to Auth Screen
```

### **3. Authentication Screen**
```
Auth Screen → User options:
├── Google Sign-In Button
│   └── OAuth Flow:
│       ├── Google Sign-In popup
│       ├── User selects account
│       ├── Firebase Auth creates user
│       └── Navigate to Role Selection
│
└── Email/Password (if implemented)
    ├── Sign Up tab
    └── Sign In tab
```

**Backend Process:**
1. User clicks "Sign in with Google"
2. Google OAuth popup appears
3. User selects Google account
4. Firebase Auth receives OAuth token
5. Firebase creates/updates user account
6. User data stored in Firestore `users` collection

### **4. Role Selection Screen**
```
After Authentication → Role Selection:
├── "I'm a Worshiper" button
│   └── Set role = worshiper
│
└── "I'm a Religious Leader" button
    └── Set role = religiousLeader
```

**Data Flow:**
- User role saved to Firestore
- Profile creation initiated

### **5. Profile Setup Screen**
```
Profile Setup → User enters:
├── Name (required)
├── Faith Type (dropdown):
│   ├── Christianity
│   ├── Islam
│   ├── Judaism
│   ├── Hinduism
│   └── Other
├── Bio (optional)
├── Profile Photo (optional)
│   └── Image Picker → Upload to Firebase Storage
│
└── "Complete Setup" button
    └── Save to Firestore → Navigate to Home
```

**Backend Process:**
1. User data validated
2. Profile photo uploaded to Firebase Storage
3. User document created/updated in Firestore `users` collection
4. FCM token registered for notifications

---

## 🏠 **Home Screen Flow (Worshiper)**

### **6. Home Screen**
```
Home Screen → Two Tabs:
├── Explore Tab
│   ├── Shows all posts from all leaders
│   ├── Infinite scroll
│   ├── Pull-to-refresh
│   └── Post Cards:
│       ├── Leader avatar & name
│       ├── Post content (text + image)
│       ├── Like button (with count)
│       ├── Comment button
│       ├── Share button
│       └── Save button
│
└── Following Tab
    ├── Shows posts from followed leaders only
    ├── Same post card UI
    └── Empty state if not following anyone
```

**Data Flow:**
1. Firestore query: `posts` collection
2. Filter by `following` list (for Following tab)
3. Order by `createdAt` descending
4. Paginate results (limit 10-20 per page)
5. Real-time updates via Firestore stream

**User Interactions:**
- **Like Post:**
  - Tap like button
  - Optimistic UI update (instant)
  - Firestore transaction: Add user ID to `likes` array
  - Update like count
  - Send notification to post author

- **Comment on Post:**
  - Tap comment button
  - Navigate to post detail screen
  - Show comments list
  - Add new comment
  - Save to Firestore `comments` subcollection
  - Send notification to post author

- **Share Post:**
  - Tap share button
  - Native share dialog
  - Share post link/content

- **Save Post:**
  - Tap save button
  - Add post ID to user's `savedPosts` array
  - Post appears in Saved Posts screen

---

## 👥 **Leader Discovery Flow**

### **7. Leaders Screen**
```
Leaders Screen → Grid View:
├── Responsive grid (1-4 columns based on screen size)
├── Leader Cards:
│   ├── Leader avatar
│   ├── Leader name
│   ├── Faith type badge
│   ├── Follower count
│   ├── Bio preview
│   └── "Follow" button
│
├── Search Bar (top)
│   └── Filter leaders by name
│
└── Filter by Faith Type (optional)
```

**Data Flow:**
1. Query Firestore `users` collection
2. Filter: `role == 'religiousLeader'`
3. Order by follower count or name
4. Display in responsive grid

**User Interactions:**
- **Follow Leader:**
  - Tap "Follow" button
  - Optimistic UI update
  - Firestore transaction:
    - Add leader ID to user's `following` array
    - Add user ID to leader's `followers` array
  - Update follower count
  - Send notification to leader

- **Tap Leader Card:**
  - Navigate to Leader Profile Screen

### **8. Leader Profile Screen**
```
Leader Profile Screen → Shows:
├── Profile Header:
│   ├── Large avatar
│   ├── Leader name
│   ├── Faith type
│   ├── Follower/Following counts
│   ├── Bio
│   └── Follow/Unfollow button
│
├── Tabs:
│   ├── Posts Tab
│   │   └── Grid/list of leader's posts
│   │
│   └── Reels Tab
│       └── Grid of leader's reels
│
└── "Message" button
    └── Navigate to Chat Detail Screen
```

**Data Flow:**
1. Fetch leader data from Firestore
2. Fetch leader's posts (filtered by `authorId`)
3. Fetch leader's reels (filtered by `authorId`)
4. Check if current user follows this leader
5. Real-time updates for follower count

---

## 💬 **Messaging Flow**

### **9. Messages Screen**
```
Messages Screen → List of Conversations:
├── Chat List Items:
│   ├── Other user's avatar
│   ├── Other user's name
│   ├── Last message preview
│   ├── Timestamp
│   ├── Unread badge (if any)
│   └── Online indicator
│
└── Floating Action Button (+)
    └── Navigate to New Message Screen
```

**Data Flow:**
1. Query Firestore `chats` collection
2. Filter: `participants` array contains current user ID
3. Order by `lastMessageAt` descending
4. For each chat, fetch other participant's data
5. Real-time updates via Firestore stream

### **10. New Message Screen**
```
New Message Screen → Select Recipient:
├── Search bar
├── List of users (filtered by search)
│   └── User cards:
│       ├── Avatar
│       ├── Name
│       └── Tap to start chat
│
└── Or select from:
    ├── Recent contacts
    └── Followed leaders
```

**Data Flow:**
1. Query Firestore `users` collection
2. Filter by search query (name)
3. Exclude current user
4. Display results

### **11. Chat Detail Screen**
```
Chat Detail Screen → Conversation View:
├── App Bar:
│   ├── Other user's name
│   ├── Online/offline status
│   └── Profile button (navigate to profile)
│
├── Message List:
│   ├── Messages grouped by date
│   ├── Message bubbles:
│   │   ├── Sent messages (right, blue)
│   │   └── Received messages (left, gray)
│   │
│   └── Message features:
│       ├── Long-press menu:
│       │   ├── Reply
│       │   ├── Edit (within 5 min)
│       │   └── Delete
│       │
│       └── Reply preview (if replying to message)
│
└── Input Area:
    ├── Text input field
    ├── Emoji button
    ├── Send button
    └── Typing indicator
```

**Data Flow:**
1. Query Firestore `chats/{chatId}/messages` subcollection
2. Order by `createdAt` ascending
3. Real-time listener for new messages
4. Mark messages as read when viewed

**User Interactions:**
- **Send Message:**
  - Type text
  - Tap send
  - Optimistic UI update (show message immediately)
  - Save to Firestore `messages` subcollection
  - Update chat's `lastMessage` and `lastMessageAt`
  - Send push notification to recipient

- **Reply to Message:**
  - Long-press message
  - Select "Reply"
  - Show reply preview in input area
  - Send message with `replyToMessageId` field
  - Display reply preview in message bubble

- **Edit Message:**
  - Long-press own message (within 5 minutes)
  - Select "Edit"
  - Pre-fill input with message text
  - Update message in Firestore
  - Show "Edited" indicator

- **Delete Message:**
  - Long-press own message
  - Select "Delete"
  - Remove from Firestore
  - Update UI

---

## 📸 **Content Creation Flow (Leader)**

### **12. Create Post Screen**
```
Create Post Screen → Leader creates post:
├── Text input (required)
├── Image picker button
│   └── Image Picker:
│       ├── Gallery option
│       ├── Camera option
│       └── Selected image preview
│
├── Upload progress indicator
└── "Publish" button
    └── Save to Firestore → Navigate back
```

**Backend Process:**
1. User enters text
2. User selects image (optional)
3. Image compressed (if needed)
4. Image uploaded to Firebase Storage
5. Get download URL
6. Create post document in Firestore:
   - `authorId`: Current user ID
   - `content`: Text content
   - `imageUrl`: Storage URL (if image)
   - `createdAt`: Timestamp
   - `likes`: Empty array
   - `comments`: Empty array
7. Send notifications to followers

### **13. Create Reel Screen**
```
Create Reel Screen → Leader creates reel:
├── Video picker button
│   └── Video Picker:
│       ├── Gallery option
│       ├── Camera option (record video)
│       └── Video preview
│
├── Caption input (optional)
├── Upload progress indicator
└── "Publish" button
    └── Save to Firestore → Navigate back
```

**Backend Process:**
1. User selects/records video
2. Video processed (compression if needed)
3. Video uploaded to Firebase Storage
4. Get download URL
5. Create reel document in Firestore:
   - `authorId`: Current user ID
   - `videoUrl`: Storage URL
   - `caption`: Text (optional)
   - `createdAt`: Timestamp
   - `likes`: Empty array
   - `views`: 0
6. Send notifications to followers

---

## 🎬 **Reels Feed Flow**

### **14. Reels Screen**
```
Reels Screen → Vertical Video Feed:
├── Full-screen video player
├── Swipe up/down to navigate
├── Auto-play on scroll
├── Video controls overlay:
│   ├── Like button
│   ├── Comment button
│   ├── Share button
│   ├── Follow button
│   └── Profile avatar (tap to profile)
│
└── Caption and author info
```

**Data Flow:**
1. Query Firestore `reels` collection
2. Order by `createdAt` descending
3. Lazy load videos (load next 3-5)
4. Play current video
5. Pause when scrolled away

**User Interactions:**
- **Like Reel:**
  - Tap like button
  - Update like count
  - Save to Firestore

- **Comment on Reel:**
  - Tap comment button
  - Show comment sheet
  - Add comment
  - Save to Firestore

- **Follow Leader:**
  - Tap follow button
  - Follow leader
  - Update button state

---

## 🗺️ **Nearby Places Flow**

### **15. Nearby Screen**
```
Nearby Screen → Map View:
├── Request location permission (first time)
├── Get current location
├── Google Places API search:
│   ├── Search radius: 10km
│   ├── Place types: religious places
│   └── Results displayed on map
│
├── Map markers for each place
├── Tap marker → Show place info:
│   ├── Place name
│   ├── Rating
│   ├── Address
│   └── "Get Directions" button
│
└── List view toggle (optional)
```

**Backend Process:**
1. Request location permission
2. Get current location (lat/lng)
3. Call Google Places API:
   - Endpoint: `/maps/api/place/nearbysearch/json`
   - Parameters:
     - `location`: Current lat/lng
     - `radius`: 10000 (10km)
     - `type`: `place_of_worship`
     - `key`: API key
4. Parse results
5. Display markers on map
6. Calculate distances

**User Interactions:**
- **Tap Marker:**
  - Show place info card
  - Display place details

- **Get Directions:**
  - Tap "Get Directions"
  - Open Google Maps app
  - Start navigation to place

---

## 🔔 **Notifications Flow**

### **16. Notifications Screen**
```
Notifications Screen → Notification List:
├── Notification Items:
│   ├── Icon (type-based)
│   ├── Title
│   ├── Message
│   ├── Timestamp
│   ├── Unread indicator
│   └── Tap → Navigate to related content
│
└── Mark all as read button
```

**Notification Types:**
1. **New Follower:**
   - "X started following you"
   - Tap → Navigate to user profile

2. **New Message:**
   - "X sent you a message"
   - Tap → Navigate to chat

3. **Post Liked:**
   - "X liked your post"
   - Tap → Navigate to post

4. **New Comment:**
   - "X commented on your post"
   - Tap → Navigate to post

5. **New Reel Like:**
   - "X liked your reel"
   - Tap → Navigate to reel

**Data Flow:**
1. Query Firestore `notifications` collection
2. Filter: `userId == currentUserId`
3. Order by `createdAt` descending
4. Mark as read when viewed
5. Real-time updates via Firestore stream

---

## 📊 **Leader Dashboard Flow**

### **17. Leader Dashboard Screen**
```
Leader Dashboard Screen → Analytics View:
├── Statistics Cards:
│   ├── Total Followers
│   ├── Total Posts
│   ├── Total Reels
│   └── Total Engagement
│
├── Charts:
│   ├── Follower growth over time
│   ├── Post engagement
│   └── Content performance
│
├── Content Management:
│   ├── My Posts button
│   ├── My Reels button
│   └── Create Content buttons
│
└── Insights Tab:
    └── Detailed analytics
```

**Data Flow:**
1. Query Firestore for:
   - Follower count: `users/{userId}/followers.length`
   - Post count: `posts` collection (filter by `authorId`)
   - Reel count: `reels` collection (filter by `authorId`)
   - Engagement: Aggregate likes, comments, shares
2. Calculate growth metrics
3. Display in charts/graphs

---

## 👤 **Profile Flow**

### **18. Profile Screen**
```
Profile Screen → User's own profile:
├── Profile Header:
│   ├── Avatar
│   ├── Name
│   ├── Bio
│   ├── Follower/Following counts
│   └── Edit Profile button
│
├── Tabs:
│   ├── Posts Tab
│   ├── Reels Tab
│   └── Saved Tab (if worshiper)
│
└── Settings button
```

**User Interactions:**
- **Edit Profile:**
  - Tap "Edit Profile"
  - Navigate to Edit Profile Screen
  - Update name, bio, photo
  - Save to Firestore

- **View Followers:**
  - Tap follower count
  - Navigate to Followers Screen

- **View Following:**
  - Tap following count
  - Navigate to Following Screen

### **19. Edit Profile Screen**
```
Edit Profile Screen → Edit details:
├── Name input
├── Bio input
├── Profile photo picker
├── Faith type selector (if applicable)
└── Save button
    └── Update Firestore → Navigate back
```

---

## 🔍 **Search Flow**

### **20. Search Screen**
```
Search Screen → Search functionality:
├── Search bar
├── Search results:
│   ├── Users tab
│   ├── Posts tab
│   └── Leaders tab
│
└── Recent searches (optional)
```

**Data Flow:**
1. User types search query
2. Query Firestore:
   - `users` collection (filter by name)
   - `posts` collection (filter by content)
   - Filter by role for leaders
3. Display results in tabs
4. Real-time search as user types

---

## ⚙️ **Settings Flow**

### **21. Settings Screen**
```
Settings Screen → App settings:
├── Account settings
├── Notification settings
├── Privacy settings
├── About section
└── Logout button
    └── Sign out → Navigate to Landing
```

**User Interactions:**
- **Logout:**
  - Tap logout
  - Clear local data
  - Sign out from Firebase Auth
  - Navigate to Landing Screen

---

## 🎯 **Complete User Journey Examples**

### **Journey 1: Worshiper Discovers and Follows Leader**
```
1. Launch app → Home Screen
2. Tap "Leaders" tab → Leaders Screen
3. Browse leaders → Tap leader card
4. View Leader Profile → Tap "Follow"
5. Return to Home → See leader's posts in Following tab
6. Like a post → Notification sent to leader
7. Tap "Message" → Start chat with leader
8. Send message → Real-time delivery
```

### **Journey 2: Leader Creates Content**
```
1. Launch app → Home Screen (as Leader)
2. Tap "Create Post" → Create Post Screen
3. Enter text → Select image → Publish
4. Post appears in feed
5. Navigate to Dashboard → View analytics
6. See follower count increase
7. Receive notification: "X liked your post"
8. Tap notification → View post engagement
```

### **Journey 3: Finding Nearby Places**
```
1. Launch app → Home Screen
2. Tap "Nearby" tab → Nearby Screen
3. Grant location permission (first time)
4. Map loads with current location
5. Religious places appear as markers
6. Tap marker → View place details
7. Tap "Get Directions" → Open Google Maps
8. Navigate to place
```

---

## 🔄 **Real-time Updates Flow**

### **How Real-time Works:**
1. **Firestore Listeners:**
   - App subscribes to Firestore streams
   - Changes trigger UI updates automatically
   - No manual refresh needed

2. **Update Scenarios:**
   - New message → Chat updates instantly
   - New post → Feed updates instantly
   - New follower → Count updates instantly
   - New notification → Badge updates instantly

3. **Optimistic Updates:**
   - UI updates immediately
   - Server sync happens in background
   - Rollback if server fails

---

**This flow documentation covers every screen and interaction in FaithConnect!**
