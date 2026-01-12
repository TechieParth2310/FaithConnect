# 🚀 FaithConnect - Quick Start Guide

## What's Already Done ✅

```
✅ Flutter project setup with clean architecture
✅ All data models (User, Post, Message, Notification)
✅ All services (Auth, Post, Message, Notification)
✅ Firebase configuration ready
✅ Dependency management set up
```

## What You Need to Do NOW

### 1️⃣ Configure Firebase (CRITICAL)

Go to `lib/firebase_options.dart` and replace with your Firebase credentials:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_APP_ID',
  messagingSenderId: 'YOUR_SENDER_ID',
  projectId: 'YOUR_PROJECT_ID',
);
```

Get these from: **Firebase Console > Project Settings**

### 2️⃣ Start Building Screens

**Start with**: `lib/screens/landing_screen.dart`

```dart
import 'package:flutter/material.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            const Text(
              'FaithConnect',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            // Description
            const Text(
              'A platform where Worshipers connect with their Religious Leaders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            // Buttons
            ElevatedButton(
              onPressed: () {
                // Navigate to signup as worshiper
              },
              child: const Text('Continue as Worshiper'),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                // Navigate to signup as religious leader
              },
              child: const Text('Continue as Religious Leader'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3️⃣ Key File Locations

| Feature       | File                                     |
| ------------- | ---------------------------------------- |
| Models        | `lib/models/`                            |
| Services      | `lib/services/`                          |
| Auth          | `lib/services/auth_service.dart`         |
| Posts         | `lib/services/post_service.dart`         |
| Messages      | `lib/services/message_service.dart`      |
| Notifications | `lib/services/notification_service.dart` |

### 4️⃣ Quick Usage Examples

#### Create a User

```dart
final authService = AuthService();
final user = await authService.signUp(
  email: 'user@example.com',
  password: 'password123',
  name: 'John Doe',
  role: UserRole.worshiper,
  faith: FaithType.christianity,
);
```

#### Create a Post

```dart
final postService = PostService();
final post = await postService.createPost(
  leaderId: 'leader_id',
  leaderName: 'Rabbi John',
  caption: 'Blessed day!',
  imageUrl: 'https://...',
);
```

#### Send a Message

```dart
final messageService = MessageService();
final message = await messageService.sendMessage(
  senderId: 'user_id',
  senderName: 'John',
  recipientId: 'leader_id',
  text: 'Hello Rabbi!',
);
```

### 5️⃣ Build & Run

```bash
cd faith_connect
flutter clean
flutter pub get
flutter run
```

### 6️⃣ Test Login

```
Email: test@faithconnect.com
Password: Test@12345
Role: Worshiper
Faith: Christianity
```

## 🎯 Priority Order

1. **Landing Screen** (30 min) → Beautiful intro
2. **Auth Screens** (2 hours) → Complete login/signup/profile
3. **Home Feed** (3 hours) → Core feature, most important
4. **Leaders Discovery** (1.5 hours) → Follow functionality
5. **Messaging** (2 hours) → Direct communication
6. **Everything else** → Polish & features

## 🎨 Color Palette (Use Consistently)

```
Primary:    #6366F1 (Indigo)
Secondary:  #8B5CF6 (Purple)
Accent:     #06B6D4 (Cyan)
Success:    #10B981 (Green)
Error:      #EF4444 (Red)
Background: #FFFFFF (White)
Text Dark:  #1F2937 (Dark Gray)
Text Light: #9CA3AF (Light Gray)
```

## 📱 Screen Sizes to Test

- Mobile: 375px wide
- Tablet: 768px wide
- Landscape: 812px high

## 🐛 Common Issues & Fixes

### Firebase Not Initializing

**Solution**: Check `firebase_options.dart` credentials

### Null Safety Errors

**Solution**: Add `?` for nullable types or `!` if sure it's non-null

### Widget Not Updating

**Solution**: Use `setState()` or Provider to manage state

### Images Not Loading

**Solution**: Check Firebase Storage rules are public (for hackathon)

## 📚 Resources

- Flutter docs: https://flutter.dev
- Firebase: https://firebase.google.com/docs/flutter
- Provider package: https://pub.dev/packages/provider

## ⚡ Speed Tips

1. Use hot reload (`r` in terminal)
2. Use Cursor AI for scaffolding
3. Don't overthink design at first
4. Focus on functionality before polish
5. Test on real device when ready

## 🎬 Demo Video Script

```
"Hey everyone, this is FaithConnect!

Here's a Worshiper signing up...
Now they can see the home feed with posts from all leaders.
They can like, comment, and follow leaders they like.
Let me follow this religious leader...
Now I can send them a direct message...

Here's a Religious Leader's view...
They can create posts with text and images...
They can see their followers and messages...
And that's FaithConnect - connecting worshipers with spiritual leaders!

Thank you!"
```

## ✅ Pre-Submission Checklist

- [ ] Firebase configured with YOUR credentials
- [ ] App builds without errors
- [ ] All screens navigate correctly
- [ ] Login/logout works
- [ ] Create post works
- [ ] Follow/unfollow works
- [ ] Messages send and receive
- [ ] No crashes on main flows
- [ ] Demo video recorded
- [ ] APK generated
- [ ] README updated
- [ ] Code is clean (no console.logs, errors)

## 🚀 You're Ready!

The hard infrastructure work is done. Now it's about building beautiful screens and connecting them together. You've got this!

**Timeline**: ~72 hours for a winning submission

Let's GO! 🎯
