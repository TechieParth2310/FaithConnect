import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

/// Centralized follow/unfollow logic.
///
/// Source of truth:
/// users/{worshipperId}.following (array of leaderIds)
/// users/{leaderId}.followers (array of worshipperIds)
///
/// Provides a real-time stream for following state.
class FollowService {
  static final FollowService _instance = FollowService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  factory FollowService() => _instance;

  FollowService._internal();

  DocumentReference<Map<String, dynamic>> _userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<UserRole?> _getUserRole(String uid) async {
    final doc = await _userRef(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return (data['role'] == 'religiousLeader')
        ? UserRole.religiousLeader
        : UserRole.worshiper;
  }

  /// Real-time stream: is current user following leaderId?
  Stream<bool> isFollowingStream({
    required String worshipperId,
    required String leaderId,
  }) {
    return _userRef(worshipperId).snapshots().map((doc) {
      final data = doc.data();
      final list = (data?['following'] as List?) ?? const [];
      return list.contains(leaderId);
    });
  }

  /// Toggle follow/unfollow.
  ///
  /// UI should optimistically update immediately; this method performs the
  /// authoritative Firestore writes.
  Future<void> setFollowing({
    required String worshipperId,
    required String leaderId,
    required bool follow,
  }) async {
    try {
      // Enforce core product rule at the service layer too:
      // ONLY leaders can be followed.
      final targetRole = await _getUserRole(leaderId);
      if (targetRole != UserRole.religiousLeader) {
        throw StateError('Only leaders can be followed.');
      }

      final batch = _firestore.batch();
      if (follow) {
        batch.update(_userRef(worshipperId), {
          'following': FieldValue.arrayUnion([leaderId]),
        });
        batch.update(_userRef(leaderId), {
          'followers': FieldValue.arrayUnion([worshipperId]),
        });
      } else {
        batch.update(_userRef(worshipperId), {
          'following': FieldValue.arrayRemove([leaderId]),
        });
        batch.update(_userRef(leaderId), {
          'followers': FieldValue.arrayRemove([worshipperId]),
        });
      }
      await batch.commit();
    } catch (e) {
      // ignore: avoid_print
      print('❌ setFollowing failed (follow=$follow): $e');
      rethrow;
    }
  }
}
