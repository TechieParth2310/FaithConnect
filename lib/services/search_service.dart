import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';

class SearchService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search leaders by name or faith
  Future<List<UserModel>> searchLeaders(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Get all religious leaders
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'religiousLeader')
          .get();

      // Filter results based on name or faith
      final results = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .where((user) {
            final nameLower = user.name.toLowerCase();
            final faithLower = user.faith
                .toString()
                .split('.')
                .last
                .toLowerCase();
            return nameLower.contains(queryLower) ||
                faithLower.contains(queryLower);
          })
          .toList();

      return results;
    } catch (e) {
      print('Error searching leaders: $e');
      return [];
    }
  }

  // Search posts by hashtags or content
  Future<List<PostModel>> searchPosts(String query) async {
    if (query.isEmpty) return [];

    try {
      final queryLower = query.toLowerCase();

      // Get all posts
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Filter results based on caption content
      final results = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) {
            final captionLower = post.caption.toLowerCase();
            return captionLower.contains(queryLower);
          })
          .toList();

      return results;
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  // Search posts by specific hashtag
  Future<List<PostModel>> searchPostsByHashtag(String hashtag) async {
    try {
      String cleanHashtag = hashtag.startsWith('#')
          ? hashtag.substring(1)
          : hashtag;
      cleanHashtag = cleanHashtag.toLowerCase();

      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      final results = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .where((post) {
            final captionLower = post.caption.toLowerCase();
            return captionLower.contains('#$cleanHashtag');
          })
          .toList();

      return results;
    } catch (e) {
      print('Error searching by hashtag: $e');
      return [];
    }
  }

  // Get trending hashtags
  Future<List<String>> getTrendingHashtags({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      // Extract all hashtags
      final Map<String, int> hashtagCounts = {};

      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        final hashtags = _extractHashtags(post.caption);

        for (var hashtag in hashtags) {
          hashtagCounts[hashtag] = (hashtagCounts[hashtag] ?? 0) + 1;
        }
      }

      // Sort by count and return top hashtags
      final sortedHashtags = hashtagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedHashtags.take(limit).map((e) => e.key).toList();
    } catch (e) {
      print('Error getting trending hashtags: $e');
      return [];
    }
  }

  // Extract hashtags from text
  List<String> _extractHashtags(String text) {
    final RegExp hashtagRegex = RegExp(r'#\w+');
    final matches = hashtagRegex.allMatches(text);
    return matches.map((match) => match.group(0)!.toLowerCase()).toList();
  }

  // Get search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.isEmpty) return [];

    try {
      final leaders = await searchLeaders(query);
      final suggestions = leaders.map((user) => user.name).toList();

      // Add trending hashtags if query starts with #
      if (query.startsWith('#')) {
        final trending = await getTrendingHashtags(limit: 5);
        suggestions.addAll(trending);
      }

      return suggestions.take(5).toList();
    } catch (e) {
      print('Error getting suggestions: $e');
      return [];
    }
  }

  // Save search to history
  Future<void> saveSearchHistory(String userId, String query) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .add({'query': query, 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  // Get search history
  Future<List<String>> getSearchHistory(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => doc.data()['query'] as String).toList();
    } catch (e) {
      print('Error getting search history: $e');
      return [];
    }
  }

  // Clear search history
  Future<void> clearSearchHistory(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('searchHistory')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing search history: $e');
    }
  }
}
