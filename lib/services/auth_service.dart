import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/index.dart';
import 'push_notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PushNotificationService _pushService = PushNotificationService();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign Up
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    required FaithType faith,
    String? profilePhotoUrl,
    String? bio,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User user = userCredential.user!;
      await user.updateDisplayName(name);

      // Create user document in Firestore
      final UserModel userModel = UserModel(
        id: user.uid,
        name: name,
        email: email,
        profilePhotoUrl: profilePhotoUrl,
        role: role,
        faith: faith,
        bio: bio,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      // Save FCM token for push notifications
      if (!kIsWeb) {
        await _pushService.saveTokenToUser(user.uid);
      }

      return userModel;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign In
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User user = userCredential.user!;
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Save FCM token for push notifications
        if (!kIsWeb) {
          await _pushService.saveTokenToUser(user.uid);
        }
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }

      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String userId,
    required UserModel updatedUser,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update(updatedUser.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Follow a leader
  Future<void> followLeader({
    required String worshiperId,
    required String leaderId,
  }) async {
    try {
      // Add leader to worshiper's following list
      await _firestore.collection('users').doc(worshiperId).update({
        'following': FieldValue.arrayUnion([leaderId]),
      });

      // Add worshiper to leader's followers list
      await _firestore.collection('users').doc(leaderId).update({
        'followers': FieldValue.arrayUnion([worshiperId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Unfollow a leader
  Future<void> unfollowLeader({
    required String worshiperId,
    required String leaderId,
  }) async {
    try {
      // Remove leader from worshiper's following list
      await _firestore.collection('users').doc(worshiperId).update({
        'following': FieldValue.arrayRemove([leaderId]),
      });

      // Remove worshiper from leader's followers list
      await _firestore.collection('users').doc(leaderId).update({
        'followers': FieldValue.arrayRemove([worshiperId]),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      // Remove FCM token before signing out
      final userId = _auth.currentUser?.uid;
      if (userId != null && !kIsWeb) {
        await _pushService.removeTokenFromUser(userId);
      }
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Update online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now(),
      });
    } catch (e) {
      // Silently fail for online status
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        // Delete user document
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user account
        await user.delete();
      }
    } catch (e) {
      rethrow;
    }
  }
}
