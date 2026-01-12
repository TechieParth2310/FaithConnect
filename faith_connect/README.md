# FaithConnect 🙏

A spiritual social networking app built with Flutter and Firebase, connecting devotees with religious leaders and communities.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Backend-orange?logo=firebase)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Project Overview

FaithConnect is a subscription-free mobile platform that connects **Worshipers** with **Religious Leaders** through:

- 🔍 Discovering spiritual content
- 👥 Following leaders
- 💬 Real-time messaging with reply, edit, delete features
- 📱 Engaging with posts (like, comment, share)
- 🎬 Short-form video reels
- 🔔 Real-time notifications
- 📊 Leader dashboards for content creation

## ✨ Key Features

### 💬 Messaging System (Telegram-Grade UX)

- **Real-time Chat** - Instant messaging powered by Firebase Firestore
- **Long-press Actions** - Reply, Edit, Delete, Forward messages
- **Message Replies** - Quote and reply to specific messages with visual preview
- **Edit Window** - Edit messages within 5 minutes of sending
- **Haptic Feedback** - Tactile response on interactions
- **Read Receipts** - Know when messages are delivered

### 📸 Content

- **Posts** - Share spiritual thoughts, images, and updates
- **Reels** - Short-form video content with full-screen viewer
- **Stories** - Ephemeral content (coming soon)

### 👥 Leaders

- **Leader Profiles** - Dedicated profiles for spiritual leaders
- **Leader Dashboard** - Analytics and content management
- **Discover Leaders** - Browse and find spiritual leaders to follow
- **Tap to Profile** - Navigate to leader profile from chat

### 🔔 Notifications

- **Real-time Notifications** - New followers, messages, likes
- **Notification Center** - View all notifications in one place

## 🏗️ Tech Stack

### Frontend

- **Framework**: Flutter 3.x (Cross-platform iOS/Android)
- **Language**: Dart
- **State Management**: Provider
- **UI Components**: Material Design 3

### Backend

- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore (Real-time)
- **Storage**: Firebase Storage (for images/videos)
- **Notifications**: Custom Firestore-based system

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── firebase_options.dart          # Firebase configuration
├── models/
│   ├── user_model.dart           # User/Profile data
│   ├── post_model.dart           # Posts & Comments
│   ├── message_model.dart        # Messages & Chats
│   └── notification_model.dart   # Notifications
├── services/
│   ├── auth_service.dart         # Authentication
│   ├── post_service.dart         # Post management
│   ├── message_service.dart      # Messaging
│   └── notification_service.dart # Notifications
├── providers/
│   ├── auth_provider.dart        # Auth state
│   ├── post_provider.dart        # Posts state
│   └── message_provider.dart     # Messages state
├── screens/
│   ├── landing_screen.dart       # Intro/Landing
│   ├── auth/                     # Auth screens
│   ├── worshiper/                # Worshiper screens
│   └── leader/                   # Leader screens
└── widgets/                      # Reusable components
```

## ✨ Key Features

### ✅ Authentication

- Email/Password signup & login
- Role selection (Worshiper vs Religious Leader)
- Profile setup with faith selection

### ✅ Worshiper Features

- Home feed (Explore & Following)
- Discover & follow leaders
- Like, comment, save posts
- Direct messaging with leaders
- Vertical reels feed
- Notifications

### ✅ Religious Leader Features

- Create posts (text + image/video)
- Create reels
- Dashboard with analytics
- Followers list
- Messaging system

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.x+
- Dart SDK 3.x+
- Firebase account
- Android Studio / VS Code

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/TechieParth2310/FaithConnect.git
   cd FaithConnect
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Add Android/iOS apps to your Firebase project
   - Download `google-services.json` (Android) → place in `android/app/`
   - Download `GoogleService-Info.plist` (iOS) → place in `ios/Runner/`

4. **Run the app**
   ```bash
   flutter run
   ```

## 🎨 Design Philosophy

- Clean, calm, respectful UI
- Smooth, intuitive flows
- Professional & accessible
- Indigo/Purple theme (#6366F1)

## 🔐 Firebase Collections

- `users` - User profiles
- `chats` - Chat conversations with subcollection `messages`
- `posts` - User posts
- `reels` - Video reels
- `notifications` - User notifications

See `firestore.indexes.json` for required composite indexes.

## 👨‍💻 Author

**Parth Kothawade**

- GitHub: [@TechieParth2310](https://github.com/TechieParth2310)

## 📄 License

This project is licensed under the MIT License.

---

**Status**: ✅ Production Ready 🚀

Made with ❤️ and 🙏 for FaithConnect Hackathon
