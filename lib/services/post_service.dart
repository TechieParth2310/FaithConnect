import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/index.dart';
import 'notification_service.dart';
import 'auth_service.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  factory PostService() {
    return _instance;
  }

  PostService._internal();

  // Upload post image to Firebase Storage (works on web and mobile)
  Future<String> uploadPostImage(XFile imageFile, String userId) async {
    try {
      final fileName =
          'posts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);

      // Read file as bytes for web compatibility
      final bytes = await imageFile.readAsBytes();
      await ref.putData(bytes);

      return await ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  // Create a new post
  Future<PostModel> createPost({
    required String leaderId,
    required String leaderName,
    required String caption,
    String? imageUrl,
    String? videoUrl,
    String? leaderProfilePhotoUrl,
  }) async {
    try {
      final postId = _firestore.collection('posts').doc().id;
      final now = DateTime.now();

      final PostModel post = PostModel(
        id: postId,
        leaderId: leaderId,
        leaderName: leaderName,
        leaderProfilePhotoUrl: leaderProfilePhotoUrl,
        caption: caption,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());
      return post;
    } catch (e) {
      rethrow;
    }
  }

  // Get all posts (for Explore) with pagination
  Stream<List<PostModel>> getAllPostsStream({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a page of posts for Explore (non-realtime).
  ///
  /// This is intentionally a one-shot fetch to reduce background work and
  /// memory pressure on the landing page. Use [startAfter] for pagination.
  Future<QuerySnapshot<Map<String, dynamic>>> getExplorePostsPage({
    int limit = 15,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  /// Get a page of posts for Following tab (non-realtime).
  ///
  /// Note: Firestore `whereIn` supports up to 10 elements. If more are
  /// provided, this method will safely truncate (UI can encourage following
  /// fewer leaders or we can upgrade to a different feed strategy later).
  Future<QuerySnapshot<Map<String, dynamic>>> getFollowingPostsPage(
    List<String> followingIds, {
    int limit = 15,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    if (followingIds.isEmpty) {
      return await _firestore.collection('posts').limit(0).get();
    }

    final ids = followingIds.length > 10
        ? followingIds.sublist(0, 10)
        : followingIds;

    Query<Map<String, dynamic>> query = _firestore
        .collection('posts')
        .where('leaderId', whereIn: ids)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  /// One-shot fetch for Explore feed (NO realtime listener).
  ///
  /// Returns a tuple-like map containing:
  /// - `posts`: List<PostModel>
  /// - `lastDoc`: DocumentSnapshot? (use for pagination)
  Future<({List<PostModel> posts, DocumentSnapshot? lastDoc})>
  fetchExplorePostsPage({int limit = 10, DocumentSnapshot? startAfter}) async {
    final baseQuery = _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit);

    final query = startAfter != null
        ? baseQuery.startAfterDocument(startAfter)
        : baseQuery;

    final snapshot = await query.get(
      const GetOptions(source: Source.serverAndCache),
    );

    final posts = snapshot.docs
        .map((doc) => PostModel.fromFirestore(doc))
        .toList();
    final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

    return (posts: posts, lastDoc: lastDoc);
  }

  // Get posts from followed leaders with pagination
  Stream<List<PostModel>> getFollowingPostsStream(
    List<String> followingIds, {
    int limit = 20,
  }) {
    if (followingIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('posts')
        .where('leaderId', whereIn: followingIds)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get posts by a specific leader
  Stream<List<PostModel>> getLeaderPostsStream(String leaderId) {
    return _firestore
        .collection('posts')
        .where('leaderId', isEqualTo: leaderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get a single post
  Future<PostModel?> getPost(String postId) async {
    try {
      final doc = await _firestore.collection('posts').doc(postId).get();
      if (doc.exists) {
        return PostModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Like a post
  Future<void> likePost({
    required String postId,
    required String userId,
  }) async {
    try {
      // Get post details for notification
      final postDoc = await _firestore.collection('posts').doc(postId).get();
      final post = PostModel.fromFirestore(postDoc);

      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });

      // Send notification to post author (if not liking own post)
      if (post.leaderId != userId) {
        final user = await _authService.getUserById(userId);
        if (user != null) {
          await _notificationService.notifyOnLike(
            postOwnerId: post.leaderId,
            userId: userId,
            userName: user.name,
            postId: postId,
            userProfileUrl: user.profilePhotoUrl,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  } // Unlike a post

  Future<void> unlikePost({
    required String postId,
    required String userId,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Save post
  Future<void> savePost(String postId, String userId) async {
    try {
      // Add post to user's saved collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .set({'postId': postId, 'savedAt': DateTime.now()});

      // Update post's saves array
      await _firestore.collection('posts').doc(postId).update({
        'saves': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unsave post
  Future<void> unsavePost(String postId, String userId) async {
    try {
      // Remove from user's saved collection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .delete();

      // Update post's saves array
      await _firestore.collection('posts').doc(postId).update({
        'saves': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get saved posts for user
  Stream<List<PostModel>> getSavedPostsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savedPosts')
        .orderBy('savedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<PostModel> savedPosts = [];
          for (var doc in snapshot.docs) {
            final postId = doc.data()['postId'] as String;
            final postDoc = await _firestore
                .collection('posts')
                .doc(postId)
                .get();
            if (postDoc.exists) {
              savedPosts.add(PostModel.fromFirestore(postDoc));
            }
          }
          return savedPosts;
        });
  }

  // Check if post is saved by user
  Future<bool> isPostSaved(String postId, String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('savedPosts')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Add comment
  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String text,
  }) async {
    try {
      final commentId = _firestore.collection('posts').doc().id;
      final comment = CommentModel(
        id: commentId,
        userId: userId,
        userName: userName,
        text: text,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(postId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Update post
  Future<void> updatePost({
    required String postId,
    required String caption,
  }) async {
    try {
      await _firestore.collection('posts').doc(postId).update({
        'caption': caption,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
