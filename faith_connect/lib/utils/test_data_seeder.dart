import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class TestDataSeeder {
  static Future<void> seedTestData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user logged in. Please login first.');
        return;
      }

      final db = FirebaseFirestore.instance;

      // Get current user data
      final currentUserDoc = await db
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!currentUserDoc.exists) {
        print('Current user data not found');
        return;
      }

      final currentUserData = UserModel.fromMap(currentUserDoc.data()!);

      print('🌱 Seeding test data...');

      // Add sample users to following/followers
      if (currentUserData.role == UserRole.worshiper) {
        // If worshiper, find some leaders to follow
        final leadersSnapshot = await db
            .collection('users')
            .where('role', isEqualTo: 'religiousLeader')
            .limit(3)
            .get();

        for (var leaderDoc in leadersSnapshot.docs) {
          if (leaderDoc.id != currentUser.uid) {
            // Add leader to current user's following list
            await db.collection('users').doc(currentUser.uid).update({
              'following': FieldValue.arrayUnion([leaderDoc.id]),
            });

            // Add current user to leader's followers list
            await db.collection('users').doc(leaderDoc.id).update({
              'followers': FieldValue.arrayUnion([currentUser.uid]),
            });

            print('✓ Now following: ${leaderDoc.data()['name']}');
          }
        }
      } else if (currentUserData.role == UserRole.religiousLeader) {
        // If leader, find some worshipers to be followers
        final worshipersSnapshot = await db
            .collection('users')
            .where('role', isEqualTo: 'worshiper')
            .limit(5)
            .get();

        for (var worshiperDoc in worshipersSnapshot.docs) {
          if (worshiperDoc.id != currentUser.uid) {
            // Add worshiper to current user's followers list
            await db.collection('users').doc(currentUser.uid).update({
              'followers': FieldValue.arrayUnion([worshiperDoc.id]),
            });

            // Add current user to worshiper's following list
            await db.collection('users').doc(worshiperDoc.id).update({
              'following': FieldValue.arrayUnion([currentUser.uid]),
            });

            print('✓ New follower: ${worshiperDoc.data()['name']}');
          }
        }
      }

      // Create some sample messages
      final allUsersSnapshot = await db.collection('users').limit(5).get();

      for (var userDoc in allUsersSnapshot.docs) {
        if (userDoc.id != currentUser.uid) {
          // Create a conversation
          final conversationId = currentUser.uid.hashCode < userDoc.id.hashCode
              ? '${currentUser.uid}_${userDoc.id}'
              : '${userDoc.id}_${currentUser.uid}';

          // Check if conversation exists
          final convDoc = await db
              .collection('conversations')
              .doc(conversationId)
              .get();

          if (!convDoc.exists) {
            // Create conversation
            await db.collection('conversations').doc(conversationId).set({
              'participants': [currentUser.uid, userDoc.id],
              'lastMessage': 'Hello! Test message',
              'lastMessageTime': FieldValue.serverTimestamp(),
              'unreadCount': {currentUser.uid: 0, userDoc.id: 1},
            });

            // Add a test message
            await db
                .collection('conversations')
                .doc(conversationId)
                .collection('messages')
                .add({
                  'senderId': currentUser.uid,
                  'text':
                      'Hello! This is a test message from ${currentUserData.name}',
                  'timestamp': FieldValue.serverTimestamp(),
                  'read': false,
                });

            print('✓ Created conversation with: ${userDoc.data()['name']}');
          }
        }
      }

      print('');
      print('✅ Test data seeded successfully!');
      print('📊 You now have:');

      // Get updated user data
      final updatedUserDoc = await db
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final updatedUser = UserModel.fromMap(updatedUserDoc.data()!);

      if (currentUserData.role == UserRole.worshiper) {
        print('   - Following: ${updatedUser.following.length} leaders');
      } else {
        print('   - Followers: ${updatedUser.followers.length} worshipers');
      }
      print('   - Test conversations in Messages');
    } catch (e) {
      print('❌ Error seeding data: $e');
    }
  }
}
