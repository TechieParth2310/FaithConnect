import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  newPost,
  newReel,
  newMessage,
  like,
  comment,
  newFollower,
}

class NotificationModel {
  final String id;
  final String userId; // Recipient ID
  final String actorId; // User who triggered notification
  final String actorName;
  final String? actorProfileUrl;
  final NotificationType type;
  final String title;

  /// Notification body/preview text.
  ///
  /// (Firestore field name: `body`)
  final String? body;
  final String? postId;
  final String? chatId; // Chat ID for message notifications
  final DateTime createdAt;
  final bool isRead;

  /// Optional stable key used to dedupe/merge notifications.
  ///
  /// Example: `${userId}_${type}_${actorId}_${postId ?? ''}_${chatId ?? ''}`
  final String? dedupeKey;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    this.actorProfileUrl,
    required this.type,
    required this.title,
    this.body,
    this.postId,
    this.chatId,
    required this.createdAt,
    this.isRead = false,
    this.dedupeKey,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'actorProfileUrl': actorProfileUrl,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'postId': postId,
      'chatId': chatId,
      'createdAt': createdAt,
      'isRead': isRead,
      'dedupeKey': dedupeKey,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      actorId: map['actorId'] ?? '',
      actorName: map['actorName'] ?? '',
      actorProfileUrl: map['actorProfileUrl'],
      type: _parseNotificationType(map['type'] ?? 'newPost'),
      title: map['title'] ?? '',
      body: map['body'] ?? map['message'],
      postId: map['postId'],
      chatId: map['chatId'],
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.parse(map['createdAt'] ?? DateTime.now().toString()),
      isRead: map['isRead'] ?? false,
      dedupeKey: map['dedupeKey'],
    );
  }

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    return NotificationModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? actorId,
    String? actorName,
    String? actorProfileUrl,
    NotificationType? type,
    String? title,
    String? body,
    String? postId,
    String? chatId,
    DateTime? createdAt,
    bool? isRead,
    String? dedupeKey,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      actorId: actorId ?? this.actorId,
      actorName: actorName ?? this.actorName,
      actorProfileUrl: actorProfileUrl ?? this.actorProfileUrl,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      postId: postId ?? this.postId,
      chatId: chatId ?? this.chatId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      dedupeKey: dedupeKey ?? this.dedupeKey,
    );
  }
}

NotificationType _parseNotificationType(String type) {
  switch (type.toLowerCase()) {
    case 'newpost':
      return NotificationType.newPost;
    case 'newreel':
      return NotificationType.newReel;
    case 'newmessage':
      return NotificationType.newMessage;
    case 'like':
      return NotificationType.like;
    case 'comment':
      return NotificationType.comment;
    case 'newfollower':
      return NotificationType.newFollower;
    default:
      return NotificationType.newPost;
  }
}
