import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/story_model.dart';
import 'auth_service.dart';

class StoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();

  // Create a new story (web-compatible)
  Future<String> createStory({
    required XFile mediaFile,
    required String mediaType,
    String? caption,
  }) async {
    try {
      final currentUser = _authService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      final userData = await _authService.getUserById(currentUser.uid);
      if (userData == null) throw Exception('User data not found');

      // Upload media to Firebase Storage (web-compatible)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = _storage.ref().child(
        'stories/${currentUser.uid}/$timestamp.${mediaType == 'video' ? 'mp4' : 'jpg'}',
      );

      // Read file as bytes for web compatibility
      final bytes = await mediaFile.readAsBytes();
      await storageRef.putData(bytes);
      final mediaUrl = await storageRef.getDownloadURL();

      // Create story document
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      final storyData = StoryModel(
        id: '',
        userId: currentUser.uid,
        userName: userData.name,
        userPhotoUrl: userData.profilePhotoUrl,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        caption: caption,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final docRef = await _firestore
          .collection('stories')
          .add(storyData.toMap());
      return docRef.id;
    } catch (e) {
      print('Error creating story: $e');
      rethrow;
    }
  }

  // Get active stories (not expired) grouped by user
  Stream<Map<String, List<StoryModel>>> getActiveStoriesStream() {
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          final stories = snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired)
              .toList();

          // Group stories by user
          final Map<String, List<StoryModel>> groupedStories = {};
          for (var story in stories) {
            if (!groupedStories.containsKey(story.userId)) {
              groupedStories[story.userId] = [];
            }
            groupedStories[story.userId]!.add(story);
          }

          // Sort each user's stories by creation date
          groupedStories.forEach((userId, userStories) {
            userStories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          });

          return groupedStories;
        });
  }

  // Get stories for a specific user
  Stream<List<StoryModel>> getUserStoriesStream(String userId) {
    return _firestore
        .collection('stories')
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => StoryModel.fromFirestore(doc))
              .where((story) => !story.isExpired)
              .toList(),
        );
  }

  // Get stories from users you follow
  Future<Map<String, List<StoryModel>>> getFollowingStories(
    List<String> followingIds,
  ) async {
    if (followingIds.isEmpty) return {};

    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('userId', whereIn: followingIds.take(10).toList())
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .orderBy('expiresAt')
          .orderBy('createdAt', descending: true)
          .get();

      final stories = snapshot.docs
          .map((doc) => StoryModel.fromFirestore(doc))
          .where((story) => !story.isExpired)
          .toList();

      // Group by user
      final Map<String, List<StoryModel>> groupedStories = {};
      for (var story in stories) {
        if (!groupedStories.containsKey(story.userId)) {
          groupedStories[story.userId] = [];
        }
        groupedStories[story.userId]!.add(story);
      }

      groupedStories.forEach((userId, userStories) {
        userStories.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      });

      return groupedStories;
    } catch (e) {
      print('Error getting following stories: $e');
      return {};
    }
  }

  // Mark story as viewed
  Future<void> viewStory(String storyId, String viewerId) async {
    try {
      final storyRef = _firestore.collection('stories').doc(storyId);
      final storyDoc = await storyRef.get();

      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);
      if (!story.viewedBy.contains(viewerId)) {
        await storyRef.update({
          'viewedBy': FieldValue.arrayUnion([viewerId]),
          'viewCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print('Error viewing story: $e');
    }
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      final storyDoc = await _firestore
          .collection('stories')
          .doc(storyId)
          .get();
      if (!storyDoc.exists) return;

      final story = StoryModel.fromFirestore(storyDoc);

      // Delete media from storage
      try {
        final storageRef = _storage.refFromURL(story.mediaUrl);
        await storageRef.delete();
      } catch (e) {
        print('Error deleting story media: $e');
      }

      // Delete story document
      await _firestore.collection('stories').doc(storyId).delete();
    } catch (e) {
      print('Error deleting story: $e');
      rethrow;
    }
  }

  // Delete expired stories (cleanup task)
  Future<void> deleteExpiredStories() async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('expiresAt', isLessThan: Timestamp.now())
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting expired stories: $e');
    }
  }

  // Get story viewers
  Future<List<String>> getStoryViewers(String storyId) async {
    try {
      final storyDoc = await _firestore
          .collection('stories')
          .doc(storyId)
          .get();
      if (!storyDoc.exists) return [];

      final story = StoryModel.fromFirestore(storyDoc);
      return story.viewedBy;
    } catch (e) {
      print('Error getting story viewers: $e');
      return [];
    }
  }

  // Check if user has active stories
  Future<bool> userHasActiveStories(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking user stories: $e');
      return false;
    }
  }
}
