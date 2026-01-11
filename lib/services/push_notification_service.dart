import 'dart:io';
import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
  // The notification will be shown automatically by FCM for background messages
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notification channel for Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'faith_connect_notifications',
    'FaithConnect Notifications',
    description: 'Notifications for likes, comments, messages, and followers',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  factory PushNotificationService() {
    return _instance;
  }

  PushNotificationService._internal();

  /// Initialize the push notification service
  Future<void> initialize() async {
    if (kIsWeb) {
      print('📱 Push notifications not supported on web');
      return;
    }

    try {
      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Create notification channel for Android
      if (Platform.isAndroid) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(_channel);
      }

      // Set up foreground notification presentation options
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      print('✅ Push notification service initialized');
    } catch (e) {
      print('❌ Error initializing push notifications: $e');
    }
  }

  /// Request notification permission
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    print('🔔 Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    // Show local notification when app is in foreground
    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: const Color(0xFF6366F1),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['type'],
      );
    }
  }

  /// Handle notification tap when app is in background/terminated
  void _handleNotificationTap(RemoteMessage message) {
    print('🔔 Notification tapped: ${message.data}');
    // Navigation will be handled by the app based on the notification type
    // The data payload contains: type, postId, chatId, etc.
  }

  /// Handle local notification tap
  void _onNotificationTap(NotificationResponse response) {
    print('🔔 Local notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  /// Get the FCM token for this device
  Future<String?> getToken() async {
    if (kIsWeb) return null;

    try {
      final token = await _messaging.getToken();
      print('📱 FCM Token: $token');
      return token;
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to user's document in Firestore
  Future<void> saveTokenToUser(String userId) async {
    if (kIsWeb) return;

    try {
      final token = await getToken();
      if (token == null) return;

      // Save token to user document
      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('✅ FCM token saved for user: $userId');
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  /// Remove FCM token when user logs out
  Future<void> removeTokenFromUser(String userId) async {
    if (kIsWeb) return;

    try {
      final token = await getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });

      print('✅ FCM token removed for user: $userId');
    } catch (e) {
      print('❌ Error removing FCM token: $e');
    }
  }

  /// Send push notification to a user (stores notification request in Firestore)
  /// Note: Actual push sending requires a backend server or Cloud Functions
  /// This method creates a notification request that can be processed by Cloud Functions
  Future<void> sendPushNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? postId,
    String? chatId,
    String? imageUrl,
  }) async {
    try {
      // Create a push notification request in Firestore
      // This will be processed by Firebase Cloud Functions to send the actual push
      await _firestore.collection('push_notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'postId': postId,
        'chatId': chatId,
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'sent': false,
      });

      print('📤 Push notification request created for user: $userId');
    } catch (e) {
      print('❌ Error creating push notification request: $e');
    }
  }

  /// Show a local notification directly (for testing or immediate display)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            color: const Color(0xFF6366F1),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
      print('✅ Local notification shown: $title');
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  /// Subscribe to a topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;

    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;

    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic: $e');
    }
  }
}
