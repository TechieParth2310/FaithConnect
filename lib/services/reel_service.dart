import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reel_model.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class ReelService {
  static final ReelService _instance = ReelService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  factory ReelService() {
    return _instance;
  }

  ReelService._internal();

  // Upload reel video to Firebase Storage (works on web and mobile)
  Future<String> uploadReelVideo(XFile videoFile, String userId) async {
    try {
      final String fileName =
          'reels/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      final Reference ref = _storage.ref().child(fileName);

      // Read file as bytes for web compatibility
      final bytes = await videoFile.readAsBytes();
      final UploadTask uploadTask = ref.putData(bytes);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Upload thumbnail (works on web and mobile)
  Future<String?> uploadThumbnail(XFile? thumbnailFile, String userId) async {
    if (thumbnailFile == null) return null;
    try {
      final String fileName =
          'reels/thumbnails/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(fileName);

      // Read file as bytes for web compatibility
      final bytes = await thumbnailFile.readAsBytes();
      final UploadTask uploadTask = ref.putData(bytes);

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  // Create a new reel
  Future<ReelModel> createReel({
    required String authorId,
    required XFile videoFile,
    XFile? thumbnailFile,
    required String caption,
  }) async {
    try {
      // Upload video
      final String videoUrl = await uploadReelVideo(videoFile, authorId);

      // Upload thumbnail if provided
      final String? thumbnailUrl = await uploadThumbnail(
        thumbnailFile,
        authorId,
      );

      // Extract hashtags
      final List<String> hashtags = ReelModel.extractHashtags(caption);

      // Create reel document
      final DocumentReference docRef = _firestore.collection('reels').doc();

      final ReelModel reel = ReelModel(
        id: docRef.id,
        authorId: authorId,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        caption: caption,
        hashtags: hashtags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await docRef.set(reel.toMap());
      return reel;
    } catch (e) {
      rethrow;
    }
  }

  // Get all reels (for feed)
  // OPTIMIZED: Added cache settings for better performance
  Stream<List<ReelModel>> getReelsStream({int limit = 20}) {
    return _firestore
        .collection('reels')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: false) // Ignore metadata changes
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList(),
        );
  }

  // Get reels by user
  Stream<List<ReelModel>> getUserReelsStream(String userId) {
    return _firestore
        .collection('reels')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList(),
        );
  }

  // Get single reel
  Future<ReelModel?> getReel(String reelId) async {
    try {
      final doc = await _firestore.collection('reels').doc(reelId).get();
      if (doc.exists) {
        return ReelModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Like a reel
  Future<void> likeReel(String reelId, String userId) async {
    try {
      // Get reel details for notification
      final reel = await getReel(reelId);

      await _firestore.collection('reels').doc(reelId).update({
        'likes': FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(1),
      });

      // Send notification to reel author (if not liking own reel)
      if (reel != null && reel.authorId != userId) {
        final user = await _authService.getUserById(userId);
        if (user != null) {
          await _notificationService.notifyOnReelLike(
            reelOwnerId: reel.authorId,
            userId: userId,
            userName: user.name,
            reelId: reelId,
            userProfileUrl: user.profilePhotoUrl,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a reel
  Future<void> unlikeReel(String reelId, String userId) async {
    try {
      await _firestore.collection('reels').doc(reelId).update({
        'likes': FieldValue.arrayRemove([userId]),
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Increment view count (Instagram-style: every time reel is opened)
  Future<void> incrementViewCount(String reelId, String userId) async {
    try {
      // Increment view count every time the reel is opened
      await _firestore.collection('reels').doc(reelId).update({
        'viewCount': FieldValue.increment(1),
      });

      print('✅ View count incremented for reel: $reelId');
    } catch (e) {
      print('❌ Error incrementing view count: $e');
      // Silently fail for view count
    }
  }

  // Add comment to reel
  Future<void> addComment({
    required String reelId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      final commentRef = _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'id': commentRef.id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': DateTime.now(),
      });

      // Increment comment count
      await _firestore.collection('reels').doc(reelId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Send notification to reel author (if not commenting on own reel)
      final reel = await getReel(reelId);
      if (reel != null && reel.authorId != userId) {
        final user = await _authService.getUserById(userId);
        if (user != null) {
          await _notificationService.notifyOnReelComment(
            reelOwnerId: reel.authorId,
            userId: userId,
            userName: user.name,
            reelId: reelId,
            comment: text,
            userProfileUrl: user.profilePhotoUrl,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Add comment with reply support
  Future<void> addCommentWithReply({
    required String reelId,
    required String userId,
    required String userName,
    required String text,
    String? replyToId,
    String? replyToUserName,
  }) async {
    try {
      final commentRef = _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'id': commentRef.id,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': DateTime.now(),
        'replyToId': replyToId,
        'replyToUserName': replyToUserName,
        'isEdited': false,
      });

      // Increment comment count
      await _firestore.collection('reels').doc(reelId).update({
        'commentCount': FieldValue.increment(1),
      });

      // Send notification to reel author (if not commenting on own reel)
      final reel = await getReel(reelId);
      if (reel != null && reel.authorId != userId) {
        final user = await _authService.getUserById(userId);
        if (user != null) {
          await _notificationService.notifyOnReelComment(
            reelOwnerId: reel.authorId,
            userId: userId,
            userName: user.name,
            reelId: reelId,
            comment: text,
            userProfileUrl: user.profilePhotoUrl,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Edit comment on reel
  Future<void> editComment({
    required String reelId,
    required String commentId,
    required String newText,
  }) async {
    try {
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .update({'text': newText, 'isEdited': true});
    } catch (e) {
      rethrow;
    }
  }

  // Delete comment on reel
  Future<void> deleteComment({
    required String reelId,
    required String commentId,
  }) async {
    try {
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .delete();

      // Decrement comment count
      await _firestore.collection('reels').doc(reelId).update({
        'commentCount': FieldValue.increment(-1),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Like a comment on reel
  Future<void> likeComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .update({
            'likedBy': FieldValue.arrayUnion([userId]),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Unlike a comment on reel
  Future<void> unlikeComment({
    required String reelId,
    required String commentId,
    required String userId,
  }) async {
    try {
      await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .doc(commentId)
          .update({
            'likedBy': FieldValue.arrayRemove([userId]),
          });
    } catch (e) {
      rethrow;
    }
  }

  // Get comments for a reel
  Stream<List<Map<String, dynamic>>> getCommentsStream(String reelId) {
    return _firestore
        .collection('reels')
        .doc(reelId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Delete reel
  Future<void> deleteReel(String reelId) async {
    try {
      // Delete all comments
      final commentsSnapshot = await _firestore
          .collection('reels')
          .doc(reelId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the reel
      await _firestore.collection('reels').doc(reelId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Search reels by hashtag
  Stream<List<ReelModel>> searchReelsByHashtag(String hashtag) {
    return _firestore
        .collection('reels')
        .where('hashtags', arrayContains: hashtag.toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList(),
        );
  }

  // Get trending reels (most liked in last 7 days)
  Future<List<ReelModel>> getTrendingReels({int limit = 20}) async {
    try {
      final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('reels')
          .where('createdAt', isGreaterThan: weekAgo)
          .orderBy('createdAt', descending: true)
          .orderBy('likeCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ReelModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }
}
