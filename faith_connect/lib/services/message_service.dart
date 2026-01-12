import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/index.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  factory MessageService() {
    return _instance;
  }

  MessageService._internal();

  bool _canEditWithinWindow(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    return diff.inMinutes <= 5;
  }

  /// Per-user conversation metadata path:
  /// users/{userId}/conversations/{conversationId}
  DocumentReference<Map<String, dynamic>> _userConversationRef({
    required String userId,
    required String conversationId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .doc(conversationId);
  }

  /// Canonical conversations collection path:
  /// conversations/{conversationId}
  ///
  /// NOTE: This app historically used `chats/{chatId}`.
  /// For hackathon safety, we keep writing to `chats` and ALSO to
  /// `conversations` so the upgraded UI can rely on the new schema.
  DocumentReference<Map<String, dynamic>> _conversationRef(
    String conversationId,
  ) {
    return _firestore.collection('conversations').doc(conversationId);
  }

  DocumentReference<Map<String, dynamic>> _legacyChatRef(String chatId) {
    return _firestore.collection('chats').doc(chatId);
  }

  // Send a message
  Future<MessageModel> sendMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
    ReplyToData? replyTo,
  }) async {
    try {
      final chatId = _getChatId(senderId, recipientId);
      final now = DateTime.now();

      // New schema IDs align with legacy chatId for simplicity.
      final conversationId = chatId;

      // --- Conversation header upsert (new + legacy) ---
      final batch = _firestore.batch();

      // New: conversations/{conversationId}
      batch.set(_conversationRef(conversationId), {
        'conversationId': conversationId,
        'participants': [senderId, recipientId],
        'lastMessage': text,
        'lastMessageAt': now,
        'lastSenderId': senderId,
      }, SetOptions(merge: true));

      // Legacy: chats/{chatId} (kept for backward compatibility)
      final legacyChatDoc = await _legacyChatRef(chatId).get();
      if (!legacyChatDoc.exists) {
        final ChatModel chat = ChatModel(
          id: chatId,
          userId1: senderId,
          userId2: recipientId,
          lastMessage: text,
          lastMessageTime: now,
          unreadCount: 1,
          lastMessageSenderId: senderId,
        );
        batch.set(
          _legacyChatRef(chatId),
          chat.toMap(),
          SetOptions(merge: true),
        );
      } else {
        batch.update(_legacyChatRef(chatId), {
          'lastMessage': text,
          'lastMessageTime': now,
          'lastMessageSenderId': senderId,
          'unreadCount': FieldValue.increment(1),
        });
      }

      // Per-user metadata (authoritative for unread)
      // Sender: keep unreadCount at 0, update lastReadAt optimistically.
      batch.set(
        _userConversationRef(userId: senderId, conversationId: conversationId),
        {
          'conversationId': conversationId,
          'otherUserId': recipientId,
          'lastReadAt': now,
          'unreadCount': 0,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      // Recipient: increment unreadCount, do NOT change lastReadAt.
      batch.set(
        _userConversationRef(
          userId: recipientId,
          conversationId: conversationId,
        ),
        {
          'conversationId': conversationId,
          'otherUserId': senderId,
          'updatedAt': now,
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // Add message to conversation sub-collection
      final messageRef = _legacyChatRef(chatId).collection('messages').doc();

      final MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        text: text,
        timestamp: now,
        replyTo: replyTo,
      );

      final msgMap = message.toMap();
      // Legacy support: make unread queries/mark-as-read reliable.
      // Some historical docs may not have this field at all.
      msgMap.putIfAbsent('isRead', () => false);
      msgMap.putIfAbsent('edited', () => false);
      await messageRef.set(msgMap);

      await batch.commit();

      // No need to update again since we already did it in the if/else block above

      // Send notification to recipient
      final sender = await _authService.getUserById(senderId);
      if (sender != null) {
        print('📨 Sending notification from ${sender.name} to $recipientId');
        await _notificationService.notifyOnMessage(
          recipientId: recipientId,
          senderId: senderId,
          senderName: sender.name,
          message: text,
          chatId: chatId,
          senderProfileUrl: sender.profilePhotoUrl,
        );
        print('✅ Notification sent successfully');
      } else {
        print('⚠️ Sender not found for ID: $senderId');
      }

      return message;
    } catch (e) {
      // ignore: avoid_print
      print('❌ sendMessage failed: $e');
      rethrow;
    }
  }

  /// Mark a conversation as read for a specific user.
  ///
  /// This is the critical fix: unread must be per-user (not a shared field on
  /// the conversation), and should reset instantly when opening the chat.
  Future<void> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    final now = DateTime.now();
    final batch = _firestore.batch();

    // Update per-user metadata (authoritative)
    batch.set(
      _userConversationRef(userId: userId, conversationId: conversationId),
      {
        'conversationId': conversationId,
        'lastReadAt': now,
        'unreadCount': 0,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    // Best-effort legacy support: mark existing unread messages as read.
    // NOTE: This is optional for UI correctness (we rely on lastReadAt/unreadCount),
    // but keeps existing isRead fields consistent.
    final legacyUnread = await _legacyChatRef(conversationId)
        .collection('messages')
        .where('recipientId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .limit(250)
        .get();
    for (final doc in legacyUnread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    try {
      await batch.commit();
    } catch (e) {
      // ignore: avoid_print
      print('❌ markConversationAsRead failed: $e');
      rethrow;
    }
  }

  // Send image message
  Future<MessageModel> sendImageMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required File imageFile,
  }) async {
    try {
      final chatId = _getChatId(senderId, recipientId);
      final now = DateTime.now();
      final conversationId = chatId;

      // Upload image to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('$chatId/${now.millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(imageFile);
      final imageUrl = await storageRef.getDownloadURL();

      final batch = _firestore.batch();

      // New: conversation header
      batch.set(_conversationRef(conversationId), {
        'conversationId': conversationId,
        'participants': [senderId, recipientId],
        'lastMessage': '📷 Photo',
        'lastMessageAt': now,
        'lastSenderId': senderId,
      }, SetOptions(merge: true));

      // Legacy: chats header
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        final ChatModel chat = ChatModel(
          id: chatId,
          userId1: senderId,
          userId2: recipientId,
          lastMessage: '📷 Photo',
          lastMessageTime: now,
          unreadCount: 1,
          lastMessageSenderId: senderId,
        );
        batch.set(_firestore.collection('chats').doc(chatId), chat.toMap());
      } else {
        batch.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': '📷 Photo',
          'lastMessageTime': now,
          'lastMessageSenderId': senderId,
          'unreadCount': FieldValue.increment(1),
        });
      }

      // Per-user metadata
      batch.set(
        _userConversationRef(userId: senderId, conversationId: conversationId),
        {
          'conversationId': conversationId,
          'otherUserId': recipientId,
          'lastReadAt': now,
          'unreadCount': 0,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      batch.set(
        _userConversationRef(
          userId: recipientId,
          conversationId: conversationId,
        ),
        {
          'conversationId': conversationId,
          'otherUserId': senderId,
          'updatedAt': now,
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // Add message to conversation sub-collection
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        text: '📷 Photo',
        timestamp: now,
        type: MessageType.image,
        imageUrl: imageUrl,
      );

      final msgMap = message.toMap();
      msgMap.putIfAbsent('isRead', () => false);
      msgMap.putIfAbsent('edited', () => false);
      await messageRef.set(msgMap);

      await batch.commit();

      // No need to update again - already done above

      return message;
    } catch (e) {
      // ignore: avoid_print
      print('❌ sendImageMessage failed: $e');
      rethrow;
    }
  }

  // Send audio message
  Future<MessageModel> sendAudioMessage({
    required String senderId,
    required String senderName,
    required String recipientId,
    required File audioFile,
    required int durationInSeconds,
  }) async {
    try {
      final chatId = _getChatId(senderId, recipientId);
      final now = DateTime.now();
      final conversationId = chatId;

      // Upload audio to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_audio')
          .child('$chatId/${now.millisecondsSinceEpoch}.m4a');

      await storageRef.putFile(audioFile);
      final audioUrl = await storageRef.getDownloadURL();

      final batch = _firestore.batch();

      // New: conversation header
      batch.set(_conversationRef(conversationId), {
        'conversationId': conversationId,
        'participants': [senderId, recipientId],
        'lastMessage': '🎤 Voice message',
        'lastMessageAt': now,
        'lastSenderId': senderId,
      }, SetOptions(merge: true));

      // Legacy: chats header
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) {
        final ChatModel chat = ChatModel(
          id: chatId,
          userId1: senderId,
          userId2: recipientId,
          lastMessage: '🎤 Voice message',
          lastMessageTime: now,
          unreadCount: 1,
          lastMessageSenderId: senderId,
        );
        batch.set(_firestore.collection('chats').doc(chatId), chat.toMap());
      } else {
        batch.update(_firestore.collection('chats').doc(chatId), {
          'lastMessage': '🎤 Voice message',
          'lastMessageTime': now,
          'lastMessageSenderId': senderId,
          'unreadCount': FieldValue.increment(1),
        });
      }

      // Per-user metadata
      batch.set(
        _userConversationRef(userId: senderId, conversationId: conversationId),
        {
          'conversationId': conversationId,
          'otherUserId': recipientId,
          'lastReadAt': now,
          'unreadCount': 0,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      batch.set(
        _userConversationRef(
          userId: recipientId,
          conversationId: conversationId,
        ),
        {
          'conversationId': conversationId,
          'otherUserId': senderId,
          'updatedAt': now,
          'unreadCount': FieldValue.increment(1),
        },
        SetOptions(merge: true),
      );

      // Add message to conversation sub-collection
      final messageRef = _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc();

      final MessageModel message = MessageModel(
        id: messageRef.id,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        text: '🎤 Voice message',
        timestamp: now,
        type: MessageType.audio,
        audioUrl: audioUrl,
        audioDuration: durationInSeconds,
      );

      final msgMap = message.toMap();
      msgMap.putIfAbsent('isRead', () => false);
      msgMap.putIfAbsent('edited', () => false);
      await messageRef.set(msgMap);

      await batch.commit();

      // No need to update again - already done above

      return message;
    } catch (e) {
      // ignore: avoid_print
      print('❌ sendAudioMessage failed: $e');
      rethrow;
    }
  }

  // Get messages between two users (using conversation-based approach)
  Stream<List<MessageModel>> getMessagesStream({
    required String userId1,
    required String userId2,
  }) {
    final chatId = _getChatId(userId1, userId2);

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(100) // Limit to latest 100 messages for performance
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MessageModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Edit a text message. Only the sender can edit, and only within 5 minutes.
  Future<void> editTextMessage({
    required String chatId,
    required MessageModel message,
    required String currentUserId,
    required String newText,
  }) async {
    if (message.senderId != currentUserId) {
      throw Exception('Not allowed to edit this message');
    }
    if (!_canEditWithinWindow(message.timestamp)) {
      throw Exception('Edit window expired');
    }
    if (message.type != MessageType.text) {
      throw Exception('Only text messages can be edited');
    }
    final trimmed = newText.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    await _legacyChatRef(chatId).collection('messages').doc(message.id).update({
      'text': trimmed,
      'edited': true,
      'editedAt': DateTime.now(),
    });
  }

  /// Delete a message (clean removal). Only the sender can delete.
  Future<void> deleteMessageForMe({
    required String chatId,
    required MessageModel message,
    required String currentUserId,
  }) async {
    if (message.senderId != currentUserId) {
      throw Exception('Not allowed to delete this message');
    }

    await _legacyChatRef(
      chatId,
    ).collection('messages').doc(message.id).delete();
  }

  /// Hard delete a message from Firestore (no placeholder).
  /// Only the sender can delete.
  Future<void> deleteMessageHard({
    required String chatId,
    required MessageModel message,
    required String currentUserId,
  }) async {
    // Same enforcement as the legacy-named method, but explicit.
    await deleteMessageForMe(
      chatId: chatId,
      message: message,
      currentUserId: currentUserId,
    );
  }

  // Get chat list for a user (query both user fields)
  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    // Firestore doesn't support OR queries easily, so we'll get all chats
    // and filter client-side (for better performance, create composite index)
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatModel.fromFirestore(doc))
              .where((chat) => chat.userId1 == userId || chat.userId2 == userId)
              .toList();
        });
  }

  // Mark messages as read in a chat
  Future<void> markChatAsRead(String chatId, String currentUserId) async {
    try {
      // Backward-compatible wrapper.
      await markConversationAsRead(
        conversationId: chatId,
        userId: currentUserId,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Real-time stream of per-user conversation metadata.
  /// This is the only listener we need for the conversation list + unread badge.
  Stream<QuerySnapshot<Map<String, dynamic>>> userConversationsStream({
    required String userId,
    int limit = 30,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) {
    var q = _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .orderBy('updatedAt', descending: true)
        .limit(limit);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }
    return q.snapshots();
  }

  /// Total unread across all conversations for a user.
  /// Used for the bottom tab badge.
  Stream<int> totalUnreadStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('conversations')
        .where('unreadCount', isGreaterThan: 0)
        .snapshots()
        .map((snap) {
          var total = 0;
          for (final d in snap.docs) {
            final v = d.data()['unreadCount'];
            if (v is int) total += v;
          }
          return total;
        });
  }

  // Delete a message
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get unread message count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final chatsSnapshot = await _firestore
          .collection('chats')
          .orderBy('lastMessageTime', descending: true)
          .get();

      int unreadCount = 0;
      for (var chatDoc in chatsSnapshot.docs) {
        final chat = ChatModel.fromFirestore(chatDoc);
        if (chat.userId1 == userId || chat.userId2 == userId) {
          final chatId = chat.id;
          final unreadMessages = await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('recipientId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();
          unreadCount += unreadMessages.docs.length;
        }
      }
      return unreadCount;
    } catch (e) {
      return 0;
    }
  }

  // Get or create a conversation between two users
  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    final chatId = _getChatId(userId1, userId2);

    // Keep IDs aligned across legacy and new schema.
    final conversationId = chatId;

    final now = DateTime.now();
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    final batch = _firestore.batch();

    // New schema: conversations header
    batch.set(_conversationRef(conversationId), {
      'conversationId': conversationId,
      'participants': [userId1, userId2],
      'lastMessage': '',
      'lastMessageAt': now,
      'lastSenderId': null,
    }, SetOptions(merge: true));

    // Legacy schema: chats header
    if (!chatDoc.exists) {
      final ChatModel chat = ChatModel(
        id: chatId,
        userId1: userId1,
        userId2: userId2,
        lastMessage: '',
        lastMessageTime: now,
        unreadCount: 0,
      );
      batch.set(_firestore.collection('chats').doc(chatId), chat.toMap());
    }

    // Per-user metadata seeds (so list can render immediately)
    batch.set(
      _userConversationRef(userId: userId1, conversationId: conversationId),
      {
        'conversationId': conversationId,
        'otherUserId': userId2,
        'lastReadAt': now,
        'unreadCount': 0,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      _userConversationRef(userId: userId2, conversationId: conversationId),
      {
        'conversationId': conversationId,
        'otherUserId': userId1,
        'lastReadAt': now,
        'unreadCount': 0,
        'updatedAt': now,
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    return chatId;
  }

  /// Delete a conversation for a specific user.
  /// This removes the conversation from the user's inbox (optimistic delete).
  /// The messages may remain in the database, but the conversation disappears from the list.
  Future<void> deleteConversation({
    required String userId,
    required String conversationId,
  }) async {
    try {
      // Delete the user's conversation metadata
      // This removes it from their inbox instantly
      await _userConversationRef(
        userId: userId,
        conversationId: conversationId,
      ).delete();
    } catch (e) {
      // ignore: avoid_print
      print('❌ deleteConversation failed: $e');
      rethrow;
    }
  }

  // Helper to create consistent chat ID
  String _getChatId(String userId1, String userId2) {
    return [userId1, userId2].sorted().join('_');
  }
}

extension ListSort on List<String> {
  List<String> sorted() {
    final list = [...this];
    list.sort();
    return list;
  }
}
