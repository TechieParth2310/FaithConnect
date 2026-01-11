import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/index.dart';
import 'push_notification_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _pushService = PushNotificationService();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  String _dedupeKey({
    required String userId,
    required NotificationType type,
    required String actorId,
    String? postId,
    String? chatId,
  }) {
    return [
      userId,
      type.toString().split('.').last,
      actorId,
      postId ?? '',
      chatId ?? '',
    ].join('_');
  }

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String actorId,
    required String actorName,
    required NotificationType type,
    required String title,
    String? message,
    String? postId,
    String? chatId,
    String? actorProfileUrl,
  }) async {
    try {
      // Prevent duplicate stacking: for the same user + actor + type (+target),
      // update the existing notification instead of creating endless docs.
      final dedupeKey = _dedupeKey(
        userId: userId,
        type: type,
        actorId: actorId,
        postId: postId,
        chatId: chatId,
      );

      final notificationId = dedupeKey;

      print('📝 Creating notification: $title for user: $userId');

      final NotificationModel notification = NotificationModel(
        id: notificationId,
        userId: userId,
        actorId: actorId,
        actorName: actorName,
        actorProfileUrl: actorProfileUrl,
        type: type,
        title: title,
        body: message,
        postId: postId,
        chatId: chatId,
        createdAt: DateTime.now(),
        isRead: false,
        dedupeKey: dedupeKey,
      );

      print('💾 Saving notification to Firestore with ID: $notificationId');
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .set(notification.toMap(), SetOptions(merge: true));
      print('✅ Notification saved successfully to Firestore');

      // Send push notification to the user's device
      await _pushService.sendPushNotification(
        userId: userId,
        title: title,
        body: message ?? _getDefaultBody(type),
        type: type.toString().split('.').last,
        postId: postId,
        chatId: chatId,
        imageUrl: actorProfileUrl,
      );
      print('📤 Push notification request sent');
    } catch (e) {
      print('❌ Error creating notification: $e');
      rethrow; // Rethrow to see the actual error
    }
  }

  // Get default body text based on notification type
  String _getDefaultBody(NotificationType type) {
    switch (type) {
      case NotificationType.like:
        return 'liked your content';
      case NotificationType.comment:
        return 'commented on your content';
      case NotificationType.newFollower:
        return 'started following you';
      case NotificationType.newMessage:
        return 'sent you a message';
      case NotificationType.newPost:
        return 'posted new content';
      case NotificationType.newReel:
        return 'posted a new reel';
    }
  }

  // Get user notifications
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    print('🔍 Fetching notifications for user: $userId');
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          print(
            '📥 Received ${snapshot.docs.length} notifications from Firestore',
          );
          final notifications = snapshot.docs
              .map((doc) {
                try {
                  return NotificationModel.fromFirestore(doc);
                } catch (e) {
                  print('❌ Error parsing notification ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<NotificationModel>()
              .toList();
          print('✅ Successfully parsed ${notifications.length} notifications');
          return notifications;
        });
  }

  // Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      print('✅ Marked ${snapshot.docs.length} notifications as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
      rethrow;
    }
  }

  /// Public API required by UX spec.
  Future<void> markAllAsReadForUser(String userId) => markAllAsRead(userId);

  /// Deletes ALL notifications for a user.
  Future<void> clearAllNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Notify followers when a leader posts
  Future<void> notifyFollowers({
    required String leaderId,
    required String leaderName,
    required List<String> followerIds,
    required String postId,
    required String? leaderProfileUrl,
  }) async {
    try {
      for (String followerId in followerIds) {
        await createNotification(
          userId: followerId,
          actorId: leaderId,
          actorName: leaderName,
          type: NotificationType.newPost,
          title: '$leaderName posted',
          message: 'Check out their new post',
          postId: postId,
          actorProfileUrl: leaderProfileUrl,
        );
      }
    } catch (e) {
      // Silent fail for follower notifications
    }
  }

  // Notify on like
  Future<void> notifyOnLike({
    required String postOwnerId,
    required String userId,
    required String userName,
    required String postId,
    required String? userProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: postOwnerId,
        actorId: userId,
        actorName: userName,
        type: NotificationType.like,
        title: '$userName liked your post',
        postId: postId,
        actorProfileUrl: userProfileUrl,
      );
    } catch (e) {
      // Silent fail for like notifications
    }
  }

  // Notify on comment
  Future<void> notifyOnComment({
    required String postOwnerId,
    required String userId,
    required String userName,
    required String postId,
    required String comment,
    required String? userProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: postOwnerId,
        actorId: userId,
        actorName: userName,
        type: NotificationType.comment,
        title: '$userName commented on your post',
        message: comment,
        postId: postId,
        actorProfileUrl: userProfileUrl,
      );
    } catch (e) {
      // Silent fail for comment notifications
    }
  }

  // Notify on new message
  Future<void> notifyOnMessage({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatId,
    required String? senderProfileUrl,
  }) async {
    try {
      print(
        '📬 Creating notification for message from $senderName to recipient: $recipientId',
      );
      await createNotification(
        userId: recipientId,
        actorId: senderId,
        actorName: senderName,
        type: NotificationType.newMessage,
        title: 'New message from $senderName',
        message: message,
        chatId: chatId,
        actorProfileUrl: senderProfileUrl,
      );
      print('✅ Notification created successfully');
    } catch (e) {
      print('❌ Error creating message notification: $e');
      // Silent fail for message notifications
    }
  }

  // Notify on new follower
  Future<void> notifyOnNewFollower({
    required String leaderId,
    required String followerId,
    required String followerName,
    required String? followerProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: leaderId,
        actorId: followerId,
        actorName: followerName,
        type: NotificationType.newFollower,
        title: '$followerName started following you',
        actorProfileUrl: followerProfileUrl,
      );
    } catch (e) {
      // Silent fail for follower notifications
    }
  }

  // Notify on reel like
  Future<void> notifyOnReelLike({
    required String reelOwnerId,
    required String userId,
    required String userName,
    required String reelId,
    required String? userProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: reelOwnerId,
        actorId: userId,
        actorName: userName,
        type: NotificationType.like,
        title: '$userName liked your reel',
        postId: reelId, // Using postId field for reelId
        actorProfileUrl: userProfileUrl,
      );
    } catch (e) {
      // Silent fail for reel like notifications
    }
  }

  // Notify on reel comment
  Future<void> notifyOnReelComment({
    required String reelOwnerId,
    required String userId,
    required String userName,
    required String reelId,
    required String comment,
    required String? userProfileUrl,
  }) async {
    try {
      await createNotification(
        userId: reelOwnerId,
        actorId: userId,
        actorName: userName,
        type: NotificationType.comment,
        title: '$userName commented on your reel',
        message: comment,
        postId: reelId, // Using postId field for reelId
        actorProfileUrl: userProfileUrl,
      );
    } catch (e) {
      // Silent fail for reel comment notifications
    }
  }
}
