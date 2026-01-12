import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/auth_service.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<UserModel> _followingUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    try {
      setState(() => _isLoading = true);

      // Get current user to access following list
      final currentUser = await AuthService().getUserById(widget.userId);

      if (currentUser != null && currentUser.following.isNotEmpty) {
        // Fetch all followed users
        List<UserModel> users = [];
        for (String leaderId in currentUser.following) {
          final leader = await AuthService().getUserById(leaderId);
          if (leader != null) {
            users.add(leader);
          }
        }

        if (mounted) {
          setState(() {
            _followingUsers = users;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _followingUsers = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading following: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unfollowUser(String leaderId) async {
    try {
      await AuthService().unfollowLeader(
        worshiperId: widget.userId,
        leaderId: leaderId,
      );

      // Remove from local list
      setState(() {
        _followingUsers.removeWhere((user) => user.id == leaderId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unfollowed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Following',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _followingUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No one followed yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Follow leaders to see them here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadFollowing,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _followingUsers.length,
                itemBuilder: (context, index) {
                  final user = _followingUsers[index];
                  return _FollowingCard(
                    user: user,
                    onUnfollow: () => _unfollowUser(user.id),
                    onTap: () {
                      // Navigate to leader profile when tapped
                      // For now, just show a snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Viewing ${user.name}')),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _FollowingCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onUnfollow;
  final VoidCallback onTap;

  const _FollowingCard({
    required this.user,
    required this.onUnfollow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF6366F1),
              backgroundImage: user.profilePhotoUrl != null
                  ? NetworkImage(user.profilePhotoUrl!)
                  : null,
              child: user.profilePhotoUrl == null
                  ? Text(
                      user.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.faith.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Unfollow button
            ElevatedButton(
              onPressed: onUnfollow,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Unfollow',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
