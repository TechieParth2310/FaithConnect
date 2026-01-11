import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, audio }

class ReplyToData {
  // New required fields (Telegram-style)
  final String replyToMessageId;
  final String replySenderName;
  final String replyPreviewText;

  // Backward-compatible aliases (historical storage used these keys)
  String get messageId => replyToMessageId;
  String get senderName => replySenderName;
  String get text => replyPreviewText;

  const ReplyToData({
    required this.replyToMessageId,
    required this.replySenderName,
    required this.replyPreviewText,
  });

  Map<String, dynamic> toMap() {
    // Write both formats for safety across old/new clients.
    return {
      'replyToMessageId': replyToMessageId,
      'replySenderName': replySenderName,
      'replyPreviewText': replyPreviewText,
      // legacy
      'messageId': replyToMessageId,
      'senderName': replySenderName,
      'text': replyPreviewText,
    };
  }

  factory ReplyToData.fromMap(Map<String, dynamic> map) {
    final replyToMessageId = (map['replyToMessageId'] ?? map['messageId'] ?? '')
        .toString();
    final replySenderName = (map['replySenderName'] ?? map['senderName'] ?? '')
        .toString();
    final replyPreviewText = (map['replyPreviewText'] ?? map['text'] ?? '')
        .toString();

    return ReplyToData(
      replyToMessageId: replyToMessageId,
      replySenderName: replySenderName,
      replyPreviewText: replyPreviewText,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool edited;
  final DateTime? editedAt;
  final MessageType type;
  final String? imageUrl;
  final String? audioUrl;
  final int? audioDuration;
  final ReplyToData? replyTo;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.edited = false,
    this.editedAt,
    this.type = MessageType.text,
    this.imageUrl,
    this.audioUrl,
    this.audioDuration,
    this.replyTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'text': text,
      'timestamp': timestamp,
      'isRead': isRead,
      'edited': edited,
      'editedAt': editedAt,
      'type': type.toString().split('.').last,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'replyTo': replyTo?.toMap(),
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    MessageType messageType = MessageType.text;
    if (map['type'] != null) {
      switch (map['type']) {
        case 'image':
          messageType = MessageType.image;
          break;
        case 'audio':
          messageType = MessageType.audio;
          break;
        default:
          messageType = MessageType.text;
      }
    }

    ReplyToData? replyTo;
    final replyRaw = map['replyTo'];
    if (replyRaw is Map<String, dynamic>) {
      replyTo = ReplyToData.fromMap(replyRaw);
    } else if (replyRaw is Map) {
      replyTo = ReplyToData.fromMap(replyRaw.map((k, v) => MapEntry('$k', v)));
    }

    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      recipientId: map['recipientId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.parse(map['timestamp'] ?? DateTime.now().toString()),
      isRead: map['isRead'] ?? false,
      edited: map['edited'] ?? false,
      editedAt: map['editedAt'] is Timestamp
          ? (map['editedAt'] as Timestamp).toDate()
          : (map['editedAt'] is String
                ? DateTime.tryParse(map['editedAt'] as String)
                : null),
      type: messageType,
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      audioDuration: map['audioDuration'],
      replyTo: replyTo,
    );
  }

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    return MessageModel.fromMap(doc.data() as Map<String, dynamic>);
  }
}

class ChatModel {
  final String id;
  final String userId1; // Worshiper ID
  final String userId2; // Leader ID
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? lastMessageSenderId; // Track who sent the last message

  ChatModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.lastMessageSenderId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId1': userId1,
      'userId2': userId2,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? '',
      userId1: map['userId1'] ?? '',
      userId2: map['userId2'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: map['lastMessageTime'] is Timestamp
          ? (map['lastMessageTime'] as Timestamp).toDate()
          : DateTime.parse(map['lastMessageTime'] ?? DateTime.now().toString()),
      unreadCount: (map['unreadCount'] is int) ? map['unreadCount'] : 0,
      lastMessageSenderId: map['lastMessageSenderId'] as String?,
    );
  }

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    return ChatModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // Check if current user has unread messages
  bool hasUnreadMessages(String currentUserId) {
    // If unreadCount is 0, definitely no unread messages
    if (unreadCount == 0) return false;

    // If unreadCount > 0, assume there are unread messages
    // UNLESS we know for sure the current user sent the last message
    if (lastMessageSenderId == null) {
      // Can't determine who sent it, but there's an unread count
      // So show badge to be safe
      return true;
    }

    // Show badge if someone else sent the last message
    return lastMessageSenderId != currentUserId;
  }
}
